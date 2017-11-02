pragma solidity ^0.4.17;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Token is ERC20 {}

contract ReserveToken is StandardToken, Claimable {
  using SafeMath for uint256;

  address public minter;

  function ReserveToken () {
  }

  function create(address _account, uint _amount) onlyOwner {
    balances[_account] = balances[_account].add(_amount);
    totalSupply = totalSupply.add(_amount);
  }

  function destroy(address _account, uint _amount) onlyOwner {
    assert (balances[_account] > _amount);
    balances[_account] = balances[_account].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
  }  

}

contract AccountLevels is Claimable {

  mapping (address => uint8) levels;

  // given a user, returns an account level
  // 0 = regular user (pays take fee and make fee)
  // 1 = market maker silver (pays take fee, no make fee, gets rebate)
  // 2 = market maker gold (pays take fee, no make fee, gets entire counterparty's take fee as rebate)
  function accountLevel(address _user) onlyOwner constant returns(uint8) {
    uint8 lvl = levels[_user];
    if (lvl != 0) return lvl;
    return 0;
  }

  function setLevel (address _user, uint8 _level) onlyOwner public returns(bool res) {
    levels[_user] = _level;
    return true;
  }
  
}

/**
 * The VXEContract contract does this and that...
 */
contract VXEContract is Claimable {

  using SafeMath for uint256;

  address public admin; // the admin address
  address public feeAccount; // the account that will receive fees
  address public accountLevelsAddr; // the address of the AccountLevels contract

  uint public feeMake; // percentage times (1 ether)
  uint public feeTake; // percentage times (1 ether)
  uint public feeRebate; // percentage times (1 ether)

  mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of _user accounts to mapping of order hashes to booleans (true = submitted by _user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint256)) public orderFills; //mapping of _user accounts to mapping of order hashes to uints (_amount of order that has been filled)

  modifier onlyAdmin() { 
    assert (msg.sender == admin); 
    _; 
  }

  event Order(address _tokenGet, uint256 _amountGet, address _tokenGive, 
              uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user);
  event Cancel(address _tokenGet, uint256 _amountGet, address _tokenGive, 
               uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user, 
               uint8 v, bytes32 r, bytes32 s);
  event Trade(address _tokenGet, uint256 _amountGet, address _tokenGive, 
              uint256 _amountGive, address get, address _give);
  event Deposit(address _token, address _user, uint256 _amount, uint256 _balance);
  event Withdraw(address _token, address _user, uint256 _amount, uint256 _balance);

  function VXEContract (address _admin, address _feeAccount, address _accountLevelsAddr, 
                        uint256 _feeMake, uint256 _feeTake, uint256 _feeRebate) {    
    admin = _admin;
    feeAccount = _feeAccount;
    accountLevelsAddr = _accountLevelsAddr;
    feeMake = _feeMake;
    feeTake = _feeTake;
    feeRebate = _feeRebate;
  }  

  // default function.
  function() {
  }

  function getAdmin () constant returns(address res) {
    return admin;
  }
  
  function changeAdmin(address _admin) onlyAdmin {
    admin = _admin;
  }

  function getAccountLevelsAddr () constant returns(address res) {
    return accountLevelsAddr;
  }
  
  function changeAccountLevelsAddr(address _accountLevelsAddr) onlyAdmin {
    accountLevelsAddr = _accountLevelsAddr;
  }

  function getFeeAccount () constant returns(address res) {
    return feeAccount;
  }
  
  function changeFeeAccount(address _feeAccount) onlyAdmin {
    feeAccount = _feeAccount;
  }

  function getFeeMake () constant returns(uint256 res) {
    return feeMake;
  }
  
  function changeFeeMake(uint256 feeMake_) onlyAdmin {
    assert (feeMake_ < feeMake);
    feeMake = feeMake_;
  }

  function getFeeTake () constant returns(uint256 res) {
    return feeTake;
  }
  
  function changeFeeTake(uint256 _feeTake) onlyAdmin {
    assert (_feeTake < feeTake || _feeTake > feeRebate);
    feeTake = _feeTake;
  }

  function getFeeRebate () constant returns(uint256 res) {
    return feeRebate;
  }
  
  function changeFeeRebate(uint256 _feeRebate) onlyAdmin {
    assert (_feeRebate > feeRebate || _feeRebate < feeTake);
    feeRebate = _feeRebate;
  }

  // the core function 
  function deposit() payable {
    tokens[0][msg.sender] = tokens[0][msg.sender].add(msg.value);
    Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }  

  function withdraw(uint _amount) {
    assert (tokens[0][msg.sender] > _amount);
    tokens[0][msg.sender] = tokens[0][msg.sender].sub(_amount);

    // this is something that has to be REMOVED.
    // Never make a call within the same contract.
    // Read further on payment/PullPayment.sol 
    // 
    assert (msg.sender.call.value(_amount)());
    Withdraw(0, msg.sender, _amount, tokens[0][msg.sender]);
  }

  function depositToken(address _token, uint _amount) {
    // remember to call Token(address).approve(this, _amount) or this contract 
    // will not be able to do the transfer on your behalf.
    assert (_token != 0 || _token != 0x0);
    assert (Token(_token).transferFrom(msg.sender, this, _amount));
    tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
    Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
  }  

  function withdrawToken(address _token, uint _amount) {
    assert (_token != 0 || _token != 0x0);
    assert (tokens[_token][msg.sender] > _amount);
    tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
    assert (Token(_token).transfer(msg.sender, _amount));
    Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
  }  

  function balanceOf(address _token, address _user) constant returns (uint) {
    return tokens[_token][_user];
  }

  function order(address _tokenGet, uint256 _amountGet, address _tokenGive, 
                 uint256 _amountGive, uint256 _expires, uint256 _nonce) {
    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    orders[msg.sender][hash] = true;
    Order(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender);
  }

  function trade(address _tokenGet, uint256 _amountGet, address _tokenGive, 
                 uint256 _amountGive, uint256 _expires, uint256 _nonce, 
                 address _user, uint8 v, bytes32 r, bytes32 s, uint256 _amount) {
    // _amount is in _amountGet terms
    bytes32 hash = getHash(_tokenGet, _amountGet, _tokenGive, _amountGive, 
                           _expires, _nonce);
    require ((
      (orders[_user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == _user) &&
      block.number <= _expires &&
      orderFills[_user][hash].add(_amount) <= _amountGet
    ));
    tradeBalances(_tokenGet, _amountGet, _tokenGive, _amountGive, _user, _amount);
    orderFills[_user][hash] = orderFills[_user][hash].add(_amount);
    Trade(_tokenGet, _amount, _tokenGive, _amountGive * _amount / _amountGet, _user, msg.sender);
  }

  function tradeBalances(address _tokenGet, uint256 _amountGet, address _tokenGive, 
                         uint256 _amountGive, address _user, uint256 _amount) 
  private {
    uint feeMakeXfer = _amount.mul(feeMake) / (1 ether);
    uint feeTakeXfer = _amount.mul(feeTake) / (1 ether);
    uint feeRebateXfer = 0;
    
    if (accountLevelsAddr != 0x0) {
      uint accountLevel = AccountLevels(accountLevelsAddr).accountLevel(_user);
      if (accountLevel == 1) feeRebateXfer = _amount.mul(feeRebate) / (1 ether);
      if (accountLevel == 2) feeRebateXfer = feeTakeXfer;
    }

    // tokens[_tokenGet][msg.sender] = safeSub(tokens[_tokenGet][msg.sender], safeAdd(_amount, feeTakeXfer));
    // tokens[_tokenGet][_user] = safeAdd(tokens[_tokenGet][_user], safeSub(safeAdd(_amount, feeRebateXfer), feeMakeXfer));
    // tokens[_tokenGet][feeAccount] = safeAdd(tokens[_tokenGet][feeAccount], safeSub(safeAdd(feeMakeXfer, feeTakeXfer), feeRebateXfer));
    // tokens[_tokenGive][_user] = safeSub(tokens[_tokenGive][_user], safeMul(_amountGive, _amount) / _amountGet);
    // tokens[_tokenGive][msg.sender] = safeAdd(tokens[_tokenGive][msg.sender], safeMul(_amountGive, _amount) / _amountGet);

    tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amount.add(feeTakeXfer));
    tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amount.add(feeRebateXfer).sub(feeMakeXfer));
    tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(feeMakeXfer.add(feeTakeXfer).sub(feeRebateXfer));
    tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive.mul(_amount) / _amountGet);
    tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive.mul(_amount) / _amountGet);
  }  

  function testTrade(address _tokenGet, uint256 _amountGet, address _tokenGive, 
                     uint256 _amountGive, uint256 _expires, uint256 _nonce, 
                     address _user, uint8 v, bytes32 r, bytes32 s, 
                     uint256 _amount, address sender) 
  constant returns(bool) {
    require ((
      tokens[_tokenGet][sender] >= _amount &&
      availableVolume(_tokenGet, _amountGet, _tokenGive, _amountGive, 
                      _expires, _nonce, _user, v, r, s) >= _amount
    ));
    return true;
  }

  function availableVolume(address _tokenGet, uint256 _amountGet, address _tokenGive, 
                           uint256 _amountGive, uint256 _expires, uint256 _nonce, 
                           address _user, uint8 v, bytes32 r, bytes32 s) 
  constant  returns(uint256) {
    bytes32 hash = getHash(_tokenGet, _amountGet, _tokenGive, _amountGive, 
                           _expires, _nonce);
    require (
      (orders[_user][hash] || 
       ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == _user) &&
      block.number <= _expires
    );
    uint256 available1 = _amountGet.sub(orderFills[_user][hash]);
    uint256 userToken = tokens[_tokenGive][_user];
    uint256 available2 = userToken.mul(_amountGet) / _amountGive;
    if (available1 < available2) return available1;
    return available2;
  }

  function amountFilled(address _tokenGet, uint256 _amountGet, address _tokenGive, 
                        uint256 _amountGive, uint256 _expires, uint256 _nonce, 
                        address _user) 
  constant returns(uint256) {
    bytes32 hash = getHash(_tokenGet, _amountGet, _tokenGive, _amountGive, 
                           _expires, _nonce);
    return orderFills[_user][hash];
  }

  function getHash (address _tokenGet, uint256 _amountGet,
                    address _tokenGive, uint256 _amountGive,
                    uint256 _expires, uint256 _nonce) 
  internal returns(bytes32 res) {
    return sha256(this, _tokenGet, _amountGet, 
                  _tokenGive, _amountGive, _expires, _nonce);
  }
  
}

