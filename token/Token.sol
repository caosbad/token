//modified as per Lition's requirement
pragma solidity 0.4.24;

import "./UpgradeableToken.sol";
import "../../zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";


contract Token is UpgradeableToken, BurnableToken {
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
        uint256 tokens;
        uint256 contributionTime;
    }

    mapping( address => Bonus ) hodlPremium;

    event UpdatedTokenInformation(string newName, string newSymbol);
    event HodlPremiumSet(address beneficiary, uint256 tokens, uint256 contributionTime);
    event HodlPremiumCapSet(uint256 newhodlPremiumCap);

    constructor (address _litWallet, address _upgradeMaster, uint256 _INITIAL_SUPPLY, uint256 _hodlPremiumCap)
        public
        UpgradeableToken(_upgradeMaster)
    {
        require(maxTokenSupply >= _INITIAL_SUPPLY * (10 ** uint256(decimals)));
        INITIAL_SUPPLY = _INITIAL_SUPPLY * (10 ** uint256(decimals));
        totalSupply_ = INITIAL_SUPPLY;
        setHodlPremiumCap(_hodlPremiumCap);
        balances[_litWallet] = INITIAL_SUPPLY;
        emit Transfer(address(0), _litWallet, INITIAL_SUPPLY);
    }

    /**
    * Owner can update token information here
    */
    function setTokenInformation(string _name, string _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;

        emit UpdatedTokenInformation(name, symbol);
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

        if (hodlPremium[beneficiary].tokens != 0) {
            hodlPremium[beneficiary].tokens = hodlPremium[beneficiary].tokens.add(value);
            emit HodlPremiumSet(beneficiary, hodlPremium[beneficiary].tokens, contributionTime);
        } else {
            hodlPremium[beneficiary] = Bonus(value, contributionTime);
            emit HodlPremiumSet(beneficiary, value, contributionTime);
        }

        return true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[msg.sender].tokens > 0) {
            uint256 amountForBonusCalculation = calculateAmountForBonus(msg.sender, _value);
            uint256 bonus = calculateBonus(msg.sender, amountForBonusCalculation);

            if ( bonus > 0) {
                balances[msg.sender] = balances[msg.sender].add(bonus);
                hodlPremium[msg.sender].tokens = hodlPremium[msg.sender].tokens.sub(amountForBonusCalculation);
                emit Transfer(address(0), msg.sender, bonus);
            }
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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
        require(_value <= allowed[_from][msg.sender]);
        require(_value <= balances[_from]);

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[_from].tokens > 0) {
            uint256 bonus = calculateBonus(_from, _value);
            uint256 amountForBonusCalculation = calculateAmountForBonus(_from, _value);

            if ( bonus > 0) {
                balances[_from] = balances[_from].add(bonus);
                hodlPremium[_from].tokens = hodlPremium[_from].tokens.sub(amountForBonusCalculation);
                emit Transfer(address(0), _from, bonus);
            }
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
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
            if (hodlPremiumMinted.add(bonusAmount) > hodlPremiumCap) {
                bonusAmount = hodlPremiumCap.sub(hodlPremiumMinted);
                hodlPremiumMinted = hodlPremiumCap;
            } else {
                bonusAmount = (((bonusPeriod.mul(amount)).div(maxBonusDuration)).mul(25)).div(100);
                hodlPremiumMinted = hodlPremiumMinted.add(bonusAmount);
            }
        }

        return bonusAmount;
    }

    function calculateAmountForBonus(address beneficiary, uint256 _value) internal view returns (uint256) {
        uint256 amountForBonusCalculation;

        if(_value >= hodlPremium[beneficiary].tokens) {
            amountForBonusCalculation = hodlPremium[msg.sender].tokens;
        } else {
            amountForBonusCalculation = _value;
        }

        return amountForBonusCalculation;
    }
}
