//modified as per Lition's requirement
pragma solidity ^0.5.0;

import "./UpgradeableToken.sol";
import "../../zeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";


contract Token is UpgradeableToken, ERC20Burnable {
    string public name;
    string public symbol;

    // For patient incentive programs
    uint256 public INITIAL_SUPPLY;
    uint256 public hodlPremiumCap;
    uint256 public hodlPremiumMinted;

    // After 180 days you get a constant maximum bonus of 25% of tokens transferred
    // Before that it is spread out linearly(from 0% to 25%) starting from the
    // contribution time till 180 days after that
    uint256 constant maxBonusDuration = 180 days;

    struct Bonus {
        uint256 hodlTokens;
        uint256 contributionTime;
        uint256 buybackTokens;
    }

    mapping( address => Bonus ) hodlPremium;

    ERC20 stablecoin;
    address stablecoinPayer;

    uint256 public signupWindowStart;
    uint256 public signupWindowEnd;

    uint256 public refundWindowStart;
    uint256 public refundWindowEnd;

    event UpdatedTokenInformation(string newName, string newSymbol);
    event HodlPremiumSet(address beneficiary, uint256 tokens, uint256 contributionTime);
    event HodlPremiumCapSet(uint256 newhodlPremiumCap);
    event RegisteredForRefund( address holder, uint256 tokens );

    constructor (address _litWallet, address _upgradeMaster, uint256 _INITIAL_SUPPLY, uint256 _hodlPremiumCap)
        public
        UpgradeableToken(_upgradeMaster)
        Ownable()
    {
        require(maxTokenSupply >= _INITIAL_SUPPLY * (10 ** uint256(decimals)));
        INITIAL_SUPPLY = _INITIAL_SUPPLY * (10 ** uint256(decimals));
        setHodlPremiumCap(_hodlPremiumCap);
        _mint(_litWallet, INITIAL_SUPPLY);
    }

    /**
    * Owner can update token information here
    */
    function setTokenInformation(string calldata _name, string calldata _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;

        emit UpdatedTokenInformation(name, symbol);
    }

    function setRefundSignupDetails( uint256 _startTime,  uint256 _endTime, ERC20 _stablecoin, address _payer ) public onlyOwner {
        stablecoin = _stablecoin;
        stablecoinPayer = _payer;
        signupWindowStart = _startTime;
        signupWindowEnd = _endTime;
        refundWindowStart = signupWindowStart + 182 days;
        refundWindowEnd = signupWindowEnd + 182 days;
    }

    function signUpForRefund( uint256 _value ) public {
        assert( hodlPremium[msg.sender].hodlTokens != 0 ); //the user was registered in ICO
        assert( block.timestamp >= signupWindowStart );
        assert( block.timestamp <= signupWindowEnd );
        uint256 value = _value;
        value = value.add(hodlPremium[msg.sender].buybackTokens);

        if( value > balanceOf(msg.sender)) //cannot register more than he or she has
            value = balanceOf(msg.sender);

        hodlPremium[ msg.sender].buybackTokens = value;

        //the invariant that holdTokens + buyBackTokens <= userBalance must hold; if not, we readjust the hodltokens
        if( hodlPremium[msg.sender].hodlTokens.add(hodlPremium[msg.sender].buybackTokens) > balanceOf(msg.sender) ){
            hodlPremium[msg.sender].hodlTokens = balanceOf(msg.sender).sub( hodlPremium[msg.sender].buybackTokens );
            emit HodlPremiumSet( msg.sender, hodlPremium[msg.sender].hodlTokens, hodlPremium[msg.sender].contributionTime );
        }

        emit RegisteredForRefund(msg.sender, value);
    }

    function refund( uint256 _value ) public {
        assert( block.timestamp >= refundWindowStart );
        assert( block.timestamp <= refundWindowEnd );
        assert( hodlPremium[msg.sender].buybackTokens >= _value );
        hodlPremium[msg.sender].buybackTokens = hodlPremium[msg.sender].buybackTokens.sub(_value);
        stablecoin.transferFrom( stablecoinPayer, msg.sender, _value);
    }

    function setHodlPremiumCap(uint256 newhodlPremiumCap) public onlyOwner {
        require(newhodlPremiumCap > 0);
        hodlPremiumCap = newhodlPremiumCap;
        emit HodlPremiumCapSet(hodlPremiumCap);
    }

    /**
    * Owner can burn token here
    */
    function burn(uint256 _value) public onlyOwner {
        super.burn(_value);
    }

    function sethodlPremium(
        address beneficiary,
        uint256 value,
        uint256 contributionTime
    )
        public
        onlyOwner
        returns (bool)
    {
        require(beneficiary != address(0) && value > 0 && contributionTime > 0, "Not eligible for HODL Premium");

        if (hodlPremium[beneficiary].hodlTokens != 0) {
            hodlPremium[beneficiary].hodlTokens = hodlPremium[beneficiary].hodlTokens.add(value);
            emit HodlPremiumSet(beneficiary, hodlPremium[beneficiary].hodlTokens, contributionTime);
        } else {
            hodlPremium[beneficiary] = Bonus(value, contributionTime, 0);
            emit HodlPremiumSet(beneficiary, value, contributionTime);
        }

        return true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[msg.sender].hodlTokens > 0) {
            uint256 amountForBonusCalculation = calculateAmountForBonus(msg.sender, _value);
            uint256 bonus = calculateBonus(msg.sender, amountForBonusCalculation);

            //subtract the tokens token into account here to avoid the above calculations in the future, e.g. in case I withdraw everything in 0 days (bonus 0), and then refund, I shall not be eligible for any bonuses
            hodlPremium[msg.sender].hodlTokens = hodlPremium[msg.sender].hodlTokens.sub(amountForBonusCalculation);
            if ( bonus > 0) {
                //balances[msg.sender] = balances[msg.sender].add(bonus);
                _mint( msg.sender, bonus );
                //emit Transfer(address(0), msg.sender, bonus);
            }
        }

        _transfer( msg.sender, _to, _value );
//        balances[msg.sender] = balances[msg.sender].sub(_value);
//        balances[_to] = balances[_to].add(_value);
//        emit Transfer(msg.sender, _to, _value);

        //TODO: optimize to avoid setting values outside of buyback window
        if( balanceOf(msg.sender) < hodlPremium[msg.sender].buybackTokens )
            hodlPremium[msg.sender].buybackTokens = balanceOf(msg.sender);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        require(_to != address(0));
        //require(_value <= allowed[_from][msg.sender]);
        //require(_value <= balances[_from]);

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[_from].hodlTokens > 0) {
            uint256 amountForBonusCalculation = calculateAmountForBonus(_from, _value);
            uint256 bonus = calculateBonus(_from, amountForBonusCalculation);

            //subtract the tokens token into account here to avoid the above calculations in the future, e.g. in case I withdraw everything in 0 days (bonus 0), and then refund, I shall not be eligible for any bonuses
            hodlPremium[_from].hodlTokens = hodlPremium[_from].hodlTokens.sub(amountForBonusCalculation);
            if ( bonus > 0) {
                //balances[_from] = balances[_from].add(bonus);
                hodlPremium[_from].hodlTokens = hodlPremium[_from].hodlTokens.sub(amountForBonusCalculation);
                _mint( msg.sender, bonus );
                //emit Transfer(address(0), _from, bonus);
            }
        }

        super.transferFrom( _from, _to, _value);
        if( balanceOf(msg.sender) < hodlPremium[msg.sender].buybackTokens )
            hodlPremium[msg.sender].buybackTokens = balanceOf(msg.sender);
        return true;
    }

    function calculateBonus(address beneficiary, uint256 amount) internal returns (uint256) {
        uint256 bonusAmount;

        uint256 contributionTime = hodlPremium[beneficiary].contributionTime;
        uint256 bonusPeriod;
        if (now <= contributionTime) {
            bonusPeriod = 0;
        } else if (now.sub(contributionTime) >= maxBonusDuration) {
            bonusPeriod = maxBonusDuration;
        } else {
            bonusPeriod = now.sub(contributionTime);
        }

        if (bonusPeriod != 0) {
            bonusAmount = (((bonusPeriod.mul(amount)).div(maxBonusDuration)).mul(25)).div(100);
            if (hodlPremiumMinted.add(bonusAmount) > hodlPremiumCap) {
                bonusAmount = hodlPremiumCap.sub(hodlPremiumMinted);
                hodlPremiumMinted = hodlPremiumCap;
            } else {
                hodlPremiumMinted = hodlPremiumMinted.add(bonusAmount);
            }
        }

        return bonusAmount;
    }

    function calculateAmountForBonus(address beneficiary, uint256 _value) internal view returns (uint256) {
        uint256 amountForBonusCalculation;

        if(_value >= hodlPremium[beneficiary].hodlTokens) {
            amountForBonusCalculation = hodlPremium[msg.sender].hodlTokens;
        } else {
            amountForBonusCalculation = _value;
        }

        return amountForBonusCalculation;
    }
}
