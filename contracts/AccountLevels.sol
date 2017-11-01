pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/ownership/Claimable.sol';

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
