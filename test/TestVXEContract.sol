pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/VXEContract.sol";

contract TestVXEContract {

  function testInitialBalanceUsingDeployedContract() {
    // VXEContract meta = VXEContract(DeployedAddresses.VXEContract());
    // uint expected = 10000;
    // Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 VXEContract initially");
  }

  function testInitialBalanceWithNewVXEContract() {
    // VXEContract meta = new VXEContract();
    // uint expected = 10000;
    // Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 VXEContract initially");
  }

}
