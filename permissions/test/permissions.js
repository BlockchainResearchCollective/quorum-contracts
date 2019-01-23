var Permissions = artifacts.require("./Permissions.sol");

function assertEventOfType(receipt, eventName, index) {
    assert.equal(receipt.logs[index].event, eventName, eventName + ' event should fire.')
}

contract('Permissions', (accounts) => {
  // 1. Initialize
  it('Permissions can only be initialized once', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.initAccounts(accounts[0])
    }).then( result => {
      assertEventOfType(result, "AccountAccessModified", 0)
      return permission.updateNetworkBootStatus()
    }).then( () => {
      return permission.getNetworkBootStatus()
    }).then( result => {
      assert.equal(result, true, "Initialized")
      return permission.addVoter(accounts[0])
    }).then( () => {
      return permission.getNumberOfVoters()
    }).then( result => {
      assert.equal(result, 1, "Number of voter equals to 1")
    })
  })
  it('Propose A Node and Cancel and Propose again', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.proposeNode("this", "is", "test", "node")
    }).then( result => {
      assertEventOfType(result, "NodeProposed", 0)
      return permission.getNodeStatus("this")
    }).then( result => {
      assert.equal(result, 1, "PendingApproval")
      return permission.cancelPendingOperation("this")
    }).then( result => {
      assertEventOfType(result, "PendingOperationCancelled", 0)
      return permission.getNumberOfNodes()
    }).then( result => {
      assert.equal(result, 1, "Number of nodes equals to 1")
      return permission.getNodeStatus("this")
    }).then( result => {
      assert.equal(result, 0, "Not In List")
      return permission.proposeNode("this", "is", "test", "node?")
    }).then( result => {
      assertEventOfType(result, "NodeProposed", 0)
      return permission.getNodeStatus("this")
    }).then( result => {
      assert.equal(result, 1, "PendingApproval")
      return permission.getNumberOfNodes()
    }).then( result => {
      assert.equal(result, 1, "Number of nodes equals to 1")
      return permission.proposeNode("this1", "is", "test", "node?")
    }).then( result => {
      assertEventOfType(result, "NodeProposed", 0)
      return permission.getNumberOfNodes()
    }).then( result => {
      assert.equal(result, 2, "Number of nodes equals to 2")
      return permission.getNodeStatus("this1")
    }).then( result => {
      assert.equal(result, 1, "PendingApproval")
      return permission.approveNode("this")
    }).then( result => {
      assertEventOfType(result, "NodeApproved", 0)
    })
  })
  it('Deactivate a node and cancel', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.proposeDeactivation("this")
    }).then( result => {
      assertEventOfType(result, "NodePendingDeactivation", 0)
      return permission.getNodeStatus("this")
    }).then( result => {
      assert.equal(result, 3, "PendingDeactivation")
      return permission.cancelPendingOperation("this")
    }).then( result => {
      assertEventOfType(result, "PendingOperationCancelled", 0)
      return permission.getNodeStatus("this")
    }).then( result => {
      assert.equal(result, 2, "Approved")
    })
  })
  it('Blacklist and cancel', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.proposeNodeBlacklisting("this", "is", "test", "node")
    }).then( result => {
      assertEventOfType(result, "NodePendingBlacklist", 0)
      return permission.proposeNodeBlacklisting("this1", "is", "test", "node")
    }).then( result => {
      assertEventOfType(result, "NodePendingBlacklist", 0)
      return permission.proposeNodeBlacklisting("this2", "is", "test", "node")
    }).then( result => {
      assertEventOfType(result, "NodePendingBlacklist", 0)
      return permission.cancelPendingOperation("this")
    }).then( result => {
      assertEventOfType(result, "PendingOperationCancelled", 0)
      return permission.getNodeStatus("this")
    }).then( result => {
      assert.equal(result, 2, "Approved")
      return permission.cancelPendingOperation("this1")
    }).then( result => {
      assertEventOfType(result, "PendingOperationCancelled", 0)
      return permission.getNodeStatus("this1")
    }).then( result => {
      assert.equal(result, 0, "NotInList")
      return permission.cancelPendingOperation("this2")
    }).then( result => {
      assertEventOfType(result, "PendingOperationCancelled", 0)
      return permission.getNodeStatus("this2")
    }).then( result => {
      assert.equal(result, 0, "NotInList")
      return permission.getNumberOfNodes()
    }).then( result => {
      assert.equal(result, 3, "Number of nodes equals to 3")
    })
  })
})
