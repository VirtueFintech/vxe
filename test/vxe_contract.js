var AccountLevels = artifacts.require("./AccountLevels.sol");
var ReserveToken = artifacts.require("./ReserveToken.sol");
var Token = artifacts.require("./Token.sol");
var VXEContract = artifacts.require("./VXEContract.sol");

contract('VXEContract', (accounts) => {

  const ether = 1000000000000000000;  // 10^18

  it("should send defined accounts", () => {
    assert.notEqual(undefined, accounts);
  });

  it("should be able to deploy VXE contract", () => {
    assert.notEqual(undefined, accounts);
    assert.equal(accounts.length, 10);

    VXEContract.new().then((inst) => {
      assert.notEqual('0x0', inst);      
    });
  });

  it("should be able to change admin", () => {
    var newAdmin = accounts[3];
    VXEContract.new().then(function(vxe) {
      vxe.changeAdmin.call(newAdmin);
      return vxe.getAdmin.call();
    }).then(function(admin) {
      assert.equal(admin, newAdmin);
    });
  });

  it("should be able to change AccountLevel contract address", () => {
    // deploy new AccountLevel
    var previous;
    VXEContract.new().then(inst => {
      AccountLevels.new().then(inst => {
        previous = inst;
        // change to 0x0;
        vxe.changeAccountLevelsAddr('0x0').then(inst => {
          assert.equal('0x0', inst);
          // change it back
          vxe.changeAccountLevelsAddr(previous).then(inst => {
            // get the address
            return inst.getAccountLevelsAddr.call();
          }).then(addr => {
            assert.equal(addr, previous);
          });
        });
      });    
    });
  });

  it("should be able to change FeeAccount address", () => {
    VXEContract.new().then(inst => {
      inst.getFeeAccount.call().then(addr => {
        var prev = addr;
        inst.changeFeeAccount.call('0x0').then(inst => {
          // get the address
          return inst.getFeeAccount.call();
        }).then(addr => {
          assert.equal('0x0', addr);
          return inst.changeFeeAccount.call(prev);
        }).then(inst => {
          return inst.getFeeAccount.call();
        }).then(addr => {
          assert.equal(addr, prev);
        });
      });
    });
  });

  it("should be able to change fee make", () => {
    var instance;
    VXEContract.new().then(inst => {
      instance = inst;
      return inst.getFeeMake().call;
    }).then(fee => {
      var prev = fee;
      // change the fee.
      instance.changeFeeMake.call(0).then(inst => {
        return inst.getFeeMake().call;
      }).then(fee => {
        assert.equal(0, fee);
        return instance.changeFeeMake.call(prev);
      }).then(inst => {
        return inst.getFeeMake().call;
      }).then(fee => {
        assert.notEqual(0, fee);
      });
    });
  });

  it("should be able to change fee take", () => {
    var instance;
    VXEContract.new().then(inst => {
      instance = inst;
      return inst.getFeeTake().call;
    }).then(fee => {
      var prev = fee;
      // change the fee.
      instance.changeFeeTake.call(0).then(inst => {
        return inst.getFeeTake().call;
      }).then(fee => {
        assert.equal(0, fee);
        return instance.changeFeeTake.call(prev);
      }).then(inst => {
        return inst.getFeeTake().call;
      }).then(fee => {
        assert.notEqual(0, fee);
      });
    });    
  });

  it("should be able to change fee rebate", () => {
    var instance;
    VXEContract.new().then(inst => {
      instance = inst;
      return inst.getFeeRebate().call;
    }).then(fee => {
      var prev = fee;
      // change the fee.
      instance.changeFeeRebate.call(0).then(inst => {
        return inst.getFeeRebate().call;
      }).then(fee => {
        assert.equal(0, fee);
        return instance.changeFeeRebate.call(prev);
      }).then(inst => {
        return inst.getFeeRebate().call;
      }).then(fee => {
        assert.notEqual(0, fee);
      });
    });        
  });

  it("should be able to deposit Ether", function() {
    var from = accounts[0]
      , amount = 1000000
      , vxe;

    return VXEContract.new().then(function(inst) {
      // deposit some ether
      vxe = inst;
      vxe.deposit.call({from: from, amount: amount});
      return vxe.balanceOf.call(0, from);
    }).then(function(balance) {
      assert.equal(balance.toNumber(), amount);
    });
  });

  it("should be able to deposit token");
  it("should be able to withdraw token");
  it("should be able to check token balance");
  it("should be able to make order");
  it("should be able to check trade balances");
  it("should be able to see available volume");
  it("should be able to see order volume filled");
});
