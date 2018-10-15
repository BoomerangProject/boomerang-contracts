pragma solidity ^0.4.17;

contract Boomerang {
    using SafeMath for uint;
    
    event ReviewRequested(
        address reviewRequest, 
        address business, 
        address customer, 
        address worker, 
        string txDetailsIPFS
    );
    event ReviewCompleted(
        address reviewRequest, 
        uint customerXpGain, 
        uint workerXpGain, 
        uint rating, 
        string reviewIPFS
    );
    event ReviewCancelled(address reviewRequest);

    EIP20 public boomToken;
    mapping(address => bool) public reviewContracts;
    mapping(address => mapping(address => uint)) public businessCustomerXp;
    mapping(address => mapping(address => uint)) public businessWorkerXp;
    
    constructor (EIP20 _boomToken) public {
        boomToken = _boomToken;
    }
    
    function requestReview(
        address _customer, 
        uint _customerBoomReward,
        uint _customerXpReward,
        address _worker,
        uint _workerBoomReward,
        uint _workerXpReward,
        string _txDetailsIPFS
    ) 
        public 
        returns(address)
    {
        require(msg.sender != _customer, "Message sender cannot be customer.");
        uint totalReward = _customerBoomReward.add(_workerBoomReward);
        ReviewRequest reviewRequest = new ReviewRequest(
            this, 
            boomToken, 
            msg.sender, 
            _customer, 
            _customerBoomReward,
            _customerXpReward, 
            _worker, 
            _workerBoomReward, 
            _workerXpReward
        );
        reviewContracts[reviewRequest] = true;
        require(
            boomToken.transferFrom(msg.sender, reviewRequest, totalReward), 
            "Not enough Boomerang tokens to request a review."
        );
        emit ReviewRequested(
            reviewRequest, msg.sender, _customer, _worker, _txDetailsIPFS
        );
        return reviewRequest;
    }
    
    function completeReview(
        uint _rating,
        string _reviewIPFS,
        address _business, 
        address _customer, 
        uint _customerXpReward,
        address _worker,
        uint _workerXpReward
    ) 
        public 
        onlyReviewContract
    {
        businessCustomerXp[_business][_customer] = 
        businessCustomerXp[_business][_customer].add(_customerXpReward);
        
        businessWorkerXp[_business][_worker] = 
        businessWorkerXp[_business][_worker].add(_workerXpReward);
        
        emit ReviewCompleted(
            msg.sender, _customerXpReward, _workerXpReward, _rating, _reviewIPFS
        );
    }
    
    function cancelReview() public onlyReviewContract {
        emit ReviewCancelled(msg.sender);
    }
    
    modifier onlyReviewContract() {
        require(
            reviewContracts[msg.sender],
            "Sender not a ReviewRequest contract."
        );
        _;
    }
}

contract ReviewRequest {
    using SafeMath for uint;
    
    uint public timeCreated;
    Boomerang public boomerang;
    EIP20 public boomToken;
    address public business;
    address public customer;
    uint public customerBoomReward;
    uint public customerXpReward;
    address public worker;
    uint public workerBoomReward;
    uint public workerXpReward;
    
    constructor(
        Boomerang _boomerang,
        EIP20 _boomToken,
        address _business, 
        address _customer, 
        uint _customerBoomReward,
        uint _customerXpReward,
        address _worker,
        uint _workerBoomReward,
        uint _workerXpReward
    ) 
        public 
    {
        timeCreated = block.timestamp;
        boomerang = _boomerang;
        boomToken = _boomToken;
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
            boomToken.transfer(worker, workerBoomReward);
            workerXpReceived = workerXpReward;
        } else {
            boomToken.transfer(business, workerBoomReward);
        }
        boomToken.transfer(customer, customerBoomReward);
        boomerang.completeReview(
            _rating,
            _reviewIPFS, 
            business, 
            customer, 
            customerXpReward, 
            worker, 
            workerXpReceived
        );
        selfdestruct(this);
    }
    
    function cancelReview() public {
        require(msg.sender == business);
        require(now >= timeCreated + 1 weeks);
        uint totalReward = customerBoomReward.add(workerBoomReward);
        boomToken.transfer(business, totalReward);
        boomerang.cancelReview();
        selfdestruct(this);
    }
}

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/

contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}