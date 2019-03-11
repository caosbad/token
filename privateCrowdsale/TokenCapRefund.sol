pragma solidity 0.4.24;

import "./BaseCrowdsale.sol";
import "./RefundVault.sol";


contract TokenCapRefund is BaseCrowdsale {
    RefundVault public vault;
    uint256 public refundClosingTime;

    modifier waitingTokenAllocation(uint256 index) {
        require(!contributions[index].tokensAllocated);
        _;
    }

    modifier greaterThanZero(uint256 value) {
        require(value > 0);
        _;
    }

    constructor(uint256 _refundClosingTime) public {
        vault = new RefundVault(wallet);

        require(_refundClosingTime > endTime);
        refundClosingTime = _refundClosingTime;
    }

    function closeRefunds() external onlyOwner {
        require(now > refundClosingTime);
        vault.close();
    }

    function enableRefunds() external onlyOwner {
        require(now > startTime);
        vault.enableRefunds();
    }

    function refundContribution(uint256 index)
        external
        onlyOwner
        waitingTokenAllocation(index)
    {
        vault.refund(contributions[index].contributor, contributions[index].weiAmount);
        weiRaised = weiRaised.sub(contributions[index].weiAmount);
        delete contributions[index];
    }

    function setRefundClosingTime(uint256 _newRefundClosingTime)
        external
        onlyOwner
        allowedUpdate(_newRefundClosingTime)
    {
        require(refundClosingTime > now);
        require(_newRefundClosingTime > endTime);

        refundClosingTime = _newRefundClosingTime;
    }

    function forwardFunds() internal {
        vault.deposit.value(msg.value)();
    }
}
