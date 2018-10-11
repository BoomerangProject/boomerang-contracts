pragma solidity ^0.4.17;

contract Boomerang {
    
    event ReviewRequested(address reviewRequest, address business, address customer, address worker, string txDetailsIPFS);
    
    function requestReview(
        address _customer, 
        uint _customerBoomReward,
        uint _customerXpReward,
        address _worker,
        uint _workerBoomReward,
        uint _workerXpReward,
        string _txDetailsIPFS) public {
            require(msg.sender != _customer);
            uint totalReward = _customerBoomReward + _workerBoomReward;
            ReviewRequest reviewRequest = new ReviewRequest(
                msg.sender, _customer, _customerBoomReward, _customerXpReward, 
                _worker, _workerBoomReward, _workerXpReward);
            // require(BoomToken.transferFrom(msg.sender, reviewRequest, totalReward));
            emit ReviewRequested(reviewRequest, msg.sender, _customer, _worker, _txDetailsIPFS);
    }
    
}

contract ReviewRequest {
    
    event ReviewSubmitted(uint rating, string reviewIPFS,  uint customerXp, uint workerXp);
    
    address public business;
    address public customer;
    uint public customerBoomReward;
    uint public customerXpReward;
    address public worker;
    uint public workerBoomReward;
    uint public workerXpReward;
    
    constructor(
        address _business, 
        address _customer, 
        uint _customerBoomReward,
        uint _customerXpReward,
        address _worker,
        uint _workerBoomReward,
        uint _workerXpReward
        ) public {
            business = _business;
            customer = _customer;
            customerBoomReward = _customerBoomReward;
            customerXpReward = _customerXpReward;
            worker = _worker;
            workerBoomReward = _workerBoomReward;
            workerXpReward = _workerXpReward;
    }
    
    function submitReview(uint _rating, string _reviewIPFS) public {
        require(msg.sender == customer);
        require(_rating >= 0 && _rating <= 2);
        uint workerXpReceived = 0;
        if (_rating == 2) {
            //BoomToken.transfer(worker, workerBoomReward)
            workerXpReceived = workerXpReward;
        } else {
            //BoomToken.transfer(business, workerBoomReward)
        }
        //BoomToken.transfer(customer, customerBoomReward)
        emit ReviewSubmitted(_rating, _reviewIPFS, customerXpReward, workerXpReceived);
        selfdestruct(this);
    }
    
}
