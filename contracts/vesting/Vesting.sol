//modified according to lition's requirements
pragma solidity ^0.5.0;

import "./CommunityVesting.sol";
import "./TeamVesting.sol";
import "./EcosystemVesting.sol";
import "./SeedPrivateAdvisorVesting.sol";
import "../../zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";


interface TokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Vesting is Ownable {
    using SafeMath for uint256;

    enum VestingUser { Public, Seed, Private, Advisor, Team, Community, Ecosystem }

    TokenInterface public token;
    CommunityVesting public communityVesting;
    TeamVesting public teamVesting;
    EcosystemVesting public ecosystemVesting;
    SeedPrivateAdvisorVesting public seedPrivateAdvisorVesting;
    mapping (address => VestingUser) public userCategory;

    event TokensReleased(address _to, uint256 _tokensReleased, VestingUser user);

    constructor(address _token) public {
        //require(_token != 0x0, "Invalid address");
        token = TokenInterface(_token);
        communityVesting = new CommunityVesting();
        teamVesting = new TeamVesting();
        ecosystemVesting = new EcosystemVesting();
        seedPrivateAdvisorVesting = new SeedPrivateAdvisorVesting();
    }

    function claimTokens() external {
        uint8 category = uint8(userCategory[msg.sender]);

        uint256 tokensToClaim;

        if (category == 1 || category == 2 || category == 3) {
            tokensToClaim = seedPrivateAdvisorVesting.claimTokens(msg.sender);
        } else if (category == 4) {
            tokensToClaim = teamVesting.claimTokens(msg.sender);
        } else if (category == 5) {
            tokensToClaim = communityVesting.claimTokens(msg.sender);
        } else {
            tokensToClaim = ecosystemVesting.claimTokens(msg.sender);
        }

        require(token.transfer(msg.sender, tokensToClaim), "Insufficient balance in vesting contract");
        emit TokensReleased(msg.sender, tokensToClaim, userCategory[msg.sender]);
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime,
        VestingUser user
    )
        external
        onlyOwner
    {
        uint8 category = uint8(user);
        require(category != 0, "Not eligible for vesting");

        userCategory[_beneficiary] = user;

        if (category == 1 || category == 2 || category == 3) {
            seedPrivateAdvisorVesting.initializeVesting(_beneficiary, _tokens, _startTime, category);
        } else if (category == 4) {
            teamVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else if (category == 5) {
            communityVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else {
            ecosystemVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        }
    }
}
