pragma solidity ^0.5.0;

import "../whitelisting/Whitelisting.sol";
import "../token/Token.sol";
import "../../zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";


contract BaseCrowdsale is Pausable, Ownable  {
    using SafeMath for uint256;

    Whitelisting public whitelisting;
    Token public token;

    struct Contribution {
        address payable contributor;
        uint256 weiAmount;
        uint256 contributionTime;
        bool tokensAllocated;
    }

    mapping (uint256 => Contribution) public contributions;
    uint256 public contributionIndex;
    uint256 public startTime;
    uint256 public endTime;
    address payable public wallet;
    uint256 public weiRaised;
    uint256 public tokenRaised;

    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event RecordedContribution(
        uint256 indexed index,
        address indexed contributor,
        uint256 weiAmount,
        uint256 time
    );

    event TokenOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier allowedUpdate(uint256 time) {
        require(time > now);
        _;
    }

    modifier checkZeroAddress(address _add) {
        require(_add != address(0));
        _;
    }

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address payable _wallet,
        Token _token,
        Whitelisting _whitelisting
    )
        public
        checkZeroAddress(_wallet)
        checkZeroAddress(address(_token))
        checkZeroAddress(address(_whitelisting))
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);

        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
        token = _token;
        whitelisting = _whitelisting;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function transferTokenOwnership(address newOwner)
        external
        onlyOwner
        checkZeroAddress(newOwner)
    {
        emit TokenOwnershipTransferred(owner(), newOwner);
        token.transferOwnership(newOwner);
    }

    function setStartTime(uint256 _newStartTime)
        external
        onlyOwner
        allowedUpdate(_newStartTime)
    {
        require(startTime > now);
        require(_newStartTime < endTime);

        startTime = _newStartTime;
    }

    function setEndTime(uint256 _newEndTime)
        external
        onlyOwner
        allowedUpdate(_newEndTime)
    {
        require(endTime > now);
        require(_newEndTime > startTime);

        endTime = _newEndTime;
    }

    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    function buyTokens(address payable beneficiary)
        internal
        whenNotPaused
        checkZeroAddress(beneficiary)
    {
        require(validPurchase());

        contributions[contributionIndex].contributor = beneficiary;
        contributions[contributionIndex].weiAmount = msg.value;
        contributions[contributionIndex].contributionTime = now;

        weiRaised = weiRaised.add(contributions[contributionIndex].weiAmount);
        emit RecordedContribution(
            contributionIndex,
            contributions[contributionIndex].contributor,
            contributions[contributionIndex].weiAmount,
            contributions[contributionIndex].contributionTime
        );

        contributionIndex++;

        forwardFunds();
    }

    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
