pragma solidity 0.4.24;

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Whitelisting is Ownable {
    mapping(address => bool) public isInvestorApproved;
    mapping(address => bool) public isInvestorPaymentApproved;

    event Approved(address indexed investor);
    event Disapproved(address indexed investor);

    event PaymentApproved(address indexed investor);
    event PaymentDisapproved(address indexed investor);


    //Token distribution approval (KYC results)
    function approveInvestor(address toApprove) public onlyOwner {
        isInvestorApproved[toApprove] = true;
        emit Approved(toApprove);
    }

    function approveInvestorsInBulk(address[] toApprove) public onlyOwner {
        for (uint i=0; i<toApprove.length; i++) {
            isInvestorApproved[toApprove[i]] = true;
            emit Approved(toApprove[i]);
        }
    }

    function disapproveInvestor(address toDisapprove) public onlyOwner {
        delete isInvestorApproved[toDisapprove];
        emit Disapproved(toDisapprove);
    }

    function disapproveInvestorsInBulk(address[] toDisapprove) public onlyOwner {
        for (uint i=0; i<toDisapprove.length; i++) {
            delete isInvestorApproved[toDisapprove[i]];
            emit Disapproved(toDisapprove[i]);
        }
    }

    //Investor payment approval (For private sale)
    function approveInvestorPayment(address toApprove) public onlyOwner {
        isInvestorPaymentApproved[toApprove] = true;
        emit PaymentApproved(toApprove);
    }

    function approveInvestorsPaymentInBulk(address[] toApprove) public onlyOwner {
        for (uint i=0; i<toApprove.length; i++) {
            isInvestorPaymentApproved[toApprove[i]] = true;
            emit PaymentApproved(toApprove[i]);
        }
    }

    function disapproveInvestorapproveInvestorPayment(address toDisapprove) public onlyOwner {
        delete isInvestorPaymentApproved[toDisapprove];
        emit PaymentDisapproved(toDisapprove);
    }

    function disapproveInvestorsPaymentInBulk(address[] toDisapprove) public onlyOwner {
        for (uint i=0; i<toDisapprove.length; i++) {
            delete isInvestorPaymentApproved[toDisapprove[i]];
            emit PaymentDisapproved(toDisapprove[i]);
        }
    }

}
