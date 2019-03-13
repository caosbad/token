pragma solidity ^0.5.0;

import "./TokenCapCrowdsale.sol";
import "./TokenCapRefund.sol";
import "../vesting/Vesting.sol";


contract PublicSale is TokenCapCrowdsale, TokenCapRefund {

    Vesting public vesting;
    mapping (address => uint256) public tokensVested;
    uint256 hodlStartTime;

    constructor (
        uint256 _startTime,
        uint256 _endTime,
        address payable _wallet,
        Whitelisting _whitelisting,
        Token _token,
        Vesting _vesting,
        uint256 _refundClosingTime,
        uint256 _refundClosingTokenCap,
        uint256 _tokenCap,
        uint256 _individualCap
    )
        public
        TokenCapCrowdsale(_tokenCap, _individualCap)
        TokenCapRefund(_refundClosingTime)
        BaseCrowdsale(_startTime, _endTime, _wallet, _token, _whitelisting)
    {
        _refundClosingTokenCap; //silence the warning
        require( address(_vesting) != address(0), "Invalid address");
        vesting = _vesting;
    }

    function allocateTokens(uint256 index, uint256 tokens)
        external
        onlyOwner
        waitingTokenAllocation(index)
    {
        address contributor = contributions[index].contributor;
        require(now >= endTime);
        require(whitelisting.isInvestorApproved(contributor));

        require(checkAndUpdateSupply(totalSupply.add(tokens)));

        uint256 alreadyExistingTokens = token.balanceOf(contributor);
        require(withinIndividualCap(tokens.add(alreadyExistingTokens)));

        contributions[index].tokensAllocated = true;
        tokenRaised = tokenRaised.add(tokens);
        token.mint(contributor, tokens);
        token.sethodlPremium(contributor, tokens, now + 7 days);

        emit TokenPurchase(
            msg.sender,
            contributor,
            contributions[index].weiAmount,
            tokens
        );
    }

    function vestTokens(address beneficiary, uint256 tokens, uint8 userType) external onlyOwner {
        require(beneficiary != address(0), "Invalid address");
        require(now >= endTime);
        require(checkAndUpdateSupply(totalSupply.add(tokens)));
        require(whitelisting.isInvestorApproved(beneficiary));

        tokensVested[beneficiary] = tokensVested[beneficiary].add(tokens);
        require(withinIndividualCap(tokensVested[beneficiary]));

        tokenRaised = tokenRaised.add(tokens);

        token.mint(address(vesting), tokens);
        Vesting(vesting).initializeVesting(beneficiary, tokens, now, Vesting.VestingUser(userType));
    }

    function ownerAssignedTokens(address beneficiary, uint256 tokens)
        external
        onlyOwner
    {
        require(now >= endTime);
        require(whitelisting.isInvestorApproved(beneficiary));

        require(checkAndUpdateSupply(totalSupply.add(tokens)));

        uint256 alreadyExistingTokens = token.balanceOf(beneficiary);
        require(withinIndividualCap(tokens.add(alreadyExistingTokens)));
        tokenRaised = tokenRaised.add(tokens);

        token.mint(beneficiary, tokens);
        token.sethodlPremium(beneficiary, tokens, hodlStartTime);

        emit TokenPurchase(
            msg.sender,
            beneficiary,
            0,
            tokens
        );
    }

    function setHodlStartTime(uint256 _hodlStartTime) onlyOwner external{
        hodlStartTime = _hodlStartTime;
    }
}
