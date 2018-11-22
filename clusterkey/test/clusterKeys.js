var ClusterKeys = artifacts.require("./ClusterKeys.sol");

function assertEventOfType(receipt, eventName, index) {
    assert.equal(receipt.logs[index].event, eventName, eventName + ' event should fire.')
}

contract('ClusterKeys', (accounts) => {
  // add a voter
  it('add a voter', () => {
    return ClusterKeys.deployed().then(instance => {
      clusterKeys = instance
      return clusterKeys.addVoter("JPM", accounts[0])
    }).then(result => {
      assertEventOfType(result, "VoterAdded", 0)
      return clusterKeys.addVoter("DBS", accounts[0])
    }).then(result => {
      assertEventOfType(result, "VoterAdded", 0)
      return clusterKeys.addVoter("JPM", accounts[1])
    }).then(result => {
      assertEventOfType(result, "VoterAdded", 0)
      return clusterKeys.addVoter("JPM", accounts[1])
    }).then(result => {
      assertEventOfType(result, "VoterExists", 0)
    })
  })
  // add an org key
  it('add an org key', () => {
    return ClusterKeys.deployed().then(instance => {
      clusterKeys = instance
      return clusterKeys.addOrgKey("JPM", "JPM1", "pk1")
    }).then(result => {
      assertEventOfType(result, "ItemForApproval", 0)
    //   return cluster.approvePendingOp("JPM1", {from:accounts[0]})
    // }).then(result => {
    //   assertEventOfType(result, "OrgKeyAdded", 0)
    })
  })
})
