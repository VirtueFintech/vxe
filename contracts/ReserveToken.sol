pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Claimable.sol';
/**
 * The ReserveToken contract does this and that...
 */
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
