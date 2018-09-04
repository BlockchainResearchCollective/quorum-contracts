var Permissions = artifacts.require("./Permissions.sol");

function assertEventOfType(receipt, eventName, index) {
    assert.equal(receipt.logs[index].event, eventName, eventName + ' event should fire.')
}

contract('Permissions', (accounts) => {
  // 1. Permissions can only be initialized once
  it('Permissions can only be initialized once', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.isInitialized()
    }).then(result => {
      assert.equal(result, false, "Initialized flag should be false before initialized")
      return permission.initialize(3, accounts.slice(0,3))
    }).then(result => {
      assertEventOfType(result, "ContractInitialized", 0)
      return permission.isInitialized()
    }).then(result => {
      assert.equal(result, true, "Initialized flag should be true after initialized")
    })
  })
  // 2. After initialization, number of nodes, number of accounts and number of voting accounts should be correct
  it('After initialization, number of nodes, number of accounts and number of voting accounts should be correct', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.getNumberOfAccounts()
    }).then(result => {
      assert.equal(result[0].toString(), 3, "account number should be 3 after intialization")
      assert.equal(result[1].toString(), 3, "voting account number should be 3 after initialization")
    })
  })
  // 3. After initialization, we should be able to get account address by index
  it('After initialization, we should be able to get account address by index', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.getAccountAddress(1)
    }).then(result => {
      assert.equal(result, "0xde47b2f33c9e74f5a9ff234e719f51f9f7d0bfe2", "account address should be equal to the first address in ganache")
    })
  })
  // 4. Only full access account can propose node, new node will be in PendingApproval status
  it('Only full access account can propose node, new node will be in PendingApproval status', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.proposeNode("this", "is", "test", "node", false)
    }).then(result => {
      assertEventOfType(result, "NewNodeProposed", 0)
      return permission.getNodeStatus("this")
    }).then(result => {
      assert.equal(result, 1, "PendingApproval status is 1")
    })
  })
  // 5. Only full access account can approve node, new node vote status and vote count should be correct
  it('Only full access account can approve node, new node vote status and vote count should be correct', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.getVoteCount("this")
    }).then(result => {
      assert.equal(result, 0, "Vote count is 0 when approval submitted")
      return permission.getVoteStatus("this", "0xDe47B2F33C9E74f5A9ff234E719f51f9F7D0bfe2")
    }).then(result => {
      assert.equal(result, false, "account 0 vote status should be false")
      return permission.approveNode("this", {from: "0xDe47B2F33C9E74f5A9ff234E719f51f9F7D0bfe2"})
    }).then(result => {
      assertEventOfType(result, "VoteNodeApproval", 0)
      return permission.getVoteStatus("this", "0xDe47B2F33C9E74f5A9ff234E719f51f9F7D0bfe2")
    }).then(result => {
      assert.equal(result, true, "account 0 vote status should be true")
      return permission.getVoteStatus("this", "0x0eEd0932d51Aa5c94FAB1ABC839AbeaE59C5875A")
    }).then(result => {
      assert.equal(result, false, "account 1 vote status should be false")
      return permission.approveNode("this", {from: "0x0eEd0932d51Aa5c94FAB1ABC839AbeaE59C5875A"})
    }).then(result => {
      assertEventOfType(result, "VoteNodeApproval", 0)
      assertEventOfType(result, "NodeApproved", 1)
      return permission.getVoteStatus("this", "0x0eEd0932d51Aa5c94FAB1ABC839AbeaE59C5875A")
    }).then(result => {
      assert.equal(result, true, "account 1 vote status should be true")
    })
  })
})
