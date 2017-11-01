
var AccountLevels = artifacts.require("./AccountLevels.sol");
var ReserveToken = artifacts.require("./ReserveToken.sol");
var Token = artifacts.require("./Token.sol");
var VXEContract = artifacts.require("./VXEContract.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(ReserveToken);
  deployer.deploy(Token);

  const ether = 1000000000000000000;  // 10^18

  // function VXEContract (address _admin, address _feeAccount, address _accountLevelsAddr, 
  //                       uint256 _feeMake, uint256 _feeTake, uint256 _feeRebate) {    

  deployer.deploy(AccountLevels).then(inst => {
    var feeMake = 0.02 * ether
      , feeTake = 0.0125 * ether
      , feeRebate = 0.002 * ether
      , admin = accounts[0]
      , feeAccount = accounts[1];

    deployer.deploy(VXEContract, admin, feeAccount, inst, feeMake, feeTake, feeRebate);
  });
};
