pragma solidity ^0.4.15;

import './Token.sol';
import './AccountLevels.sol';

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Claimable.sol';

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
      (orders[_user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == _user) &&
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
  constant returns(uint256) {
    bytes32 hash = getHash(_tokenGet, _amountGet, _tokenGive, _amountGive, 
                           _expires, _nonce);
    require (
      (orders[_user][hash] || 
       ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == _user) &&
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

