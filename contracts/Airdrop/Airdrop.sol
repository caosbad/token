pragma solidity ^0.5.0;

import "../../zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";


interface IERC20 {
    function transfer(address to, uint value) external returns (bool ok);
    function balanceOf(address _owner) external view returns (uint256 balance);
}


contract Airdrop is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public individualCap;
    uint256 public totalAlloctedToken;
    mapping (address => uint256) airdropContribution;
    event Airdroped(address to, uint256 token);

    constructor (
        IERC20 _tokenAddr,
        uint256 _individualCap
    )
        public
    {
        token = _tokenAddr;
        individualCap = _individualCap;
    }

    function drop(address[] calldata _recipients, uint256[] calldata _amount)
        external 
        onlyOwner returns (bool) 
    {
        require(_recipients.length == _amount.length);
        
        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Address is zero address");
            require(individualCap >= airdropContribution[_recipients[i]].add(_amount[i]), "Exceding individual cap");
            require(token.balanceOf(address(this)) >= _amount[i], "No enoufgh tokens available");
            airdropContribution[_recipients[i]] = airdropContribution[_recipients[i]].add(_amount[i]);
            totalAlloctedToken = totalAlloctedToken.add(_amount[i]);
            token.transfer(_recipients[i], _amount[i]);
            emit Airdroped(_recipients[i], _amount[i]);
        }
        return true;
    }

    function updateIndividualCap(uint256 _value) external onlyOwner {
        require(individualCap > 0, "Individual Cap should be greater than zero");
        individualCap = _value;
    }
}