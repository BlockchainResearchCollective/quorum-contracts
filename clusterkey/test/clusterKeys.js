var ClusterKeys = artifacts.require("./ClusterKeys.sol");

function assertEventOfType(receipt, eventName, index) {
    assert.equal(receipt.logs[index].event, eventName, eventName + ' event should fire.')
}

contract('ClusterKeys', (accounts) => {
  // add master org
  it('add master org', () => {
    return ClusterKeys.deployed().then(instance => {
      clusterKeys = instance
      return clusterKeys.addMasterOrg("JPM", {from:accounts[0]})
    }).then(result => {
      assertEventOfType(result, "MasterOrgAdded", 0)
      return clusterKeys.addSubOrg("JPM1", "JPM", {from:accounts[0]})
    }).then(result => {
      assertEventOfType(result, "SubOrgAdded", 0)
    })
  })
  // add a voter
  it('add a voter', () => {
    return ClusterKeys.deployed().then(instance => {
      clusterKeys = instance
      return clusterKeys.addVoter("JPM", accounts[0], {from:accounts[0]})
    }).then(result => {
      assertEventOfType(result, "VoterAdded", 0)
    })
  })
  // add org key
  it('add org key', () => {
    return ClusterKeys.deployed().then(instance => {
      clusterKeys = instance
      return clusterKeys.addOrgKey("JPM1", "BULeR8JyUWhiuuCMU/HLA0Q5pzkYT+cHII3ZKBey3Bo=", {from: accounts[0]})
    }).then(result => {
      assertEventOfType(result, "ItemForApproval", 0)
      return clusterKeys.getOrgVoteCount("JPM1")
    }).then(result => {
      assert.equal(result, 0)
      return clusterKeys.approvePendingOp("JPM1", {from:accounts[0]})
    }).then(result => {
      assertEventOfType(result, "OrgKeyAdded", 0)
      return clusterKeys.getOrgVoteCount("JPM1")
    }).then(result => {
      assert.equal(result, 1)
      return clusterKeys.getVoteStatus("JPM1", {from: accounts[0]})
    }).then(result => {
      assert.equal(result, true)
    })
  })
  // add sub org
  it('add sub org', () => {
    return ClusterKeys.deployed().then(instance => {
      clusterKeys = instance
      return clusterKeys.addSubOrg("JPM2", "JPM", {from:accounts[0]})
    }).then(result => {
      assertEventOfType(result, "SubOrgAdded", 0)
    })
  })
  // add another org key
  it('add another org key', () => {
    return ClusterKeys.deployed().then(instance => {
      clusterKeys = instance
      return clusterKeys.addOrgKey("JPM2", "BULeR8JyUWhiuuCMU/HLA0Q5pzkYT+cHII3ZKBey3Bo=", {from: accounts[0]})
    }).then(result => {
      assertEventOfType(result, "ItemForApproval", 0)
      return clusterKeys.getPendingOp("JPM2")
    }).then(result => {
      assert.equal(result[0], "BULeR8JyUWhiuuCMU/HLA0Q5pzkYT+cHII3ZKBey3Bo=")
      assert.equal(result[1], 1)
      return clusterKeys.getVoteStatus("JPM2", {from: accounts[0]})
    }).then(result => {
      assert.equal(result, false)
      return clusterKeys.getOrgVoteCount("JPM2")
    }).then(result => {
      assert.equal(result, 0)
      return clusterKeys.approvePendingOp("JPM2", {from:accounts[0]})
    }).then(result => {
      assertEventOfType(result, "OrgKeyAdded", 0)
      return clusterKeys.getOrgVoteCount("JPM2")
    }).then(result => {
      assert.equal(result, 1)
      return clusterKeys.getVoteStatus("JPM2", {from: accounts[0]})
    }).then(result => {
      assert.equal(result, true)
    })
  })
})
