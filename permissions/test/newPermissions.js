var Permissions = artifacts.require("./NewPermissions.sol");

function assertEventOfType(receipt, eventName, index) {
    assert.equal(receipt.logs[index].event, eventName, eventName + ' event should fire.')
}

contract('Permissions', (accounts) => {
  // Can not propose before add any vote account
  it('Can not propose before add any vote account', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.proposeNode("this", "is", "test", "node", false) // "this" is the enodeId
    }).then(result => {
      assertEventOfType(result, "NoVotingAccount", 0)
    })
  })
  // Can propose after account added
  it('Can propose after account added', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.addVoter(accounts[0])
    }).then(result => {
      assertEventOfType(result, "VoterAdded", 0)
      return permission.addVoter(accounts[1])
    }).then(result => {
      assertEventOfType(result, "VoterAdded", 0)
      return permission.addVoter(accounts[2])
    }).then(result => {
      assertEventOfType(result, "VoterAdded", 0)
      return permission.getNumberOfAccounts()
    }).then(result => {
      assert.equal(result.toString(), 3, "3 accounts in list")
      return permission.addVoter(accounts[0])
    }).then(result => {
      assert.equal(result.logs[0], undefined, "Add voter fail")
      return permission.proposeNode("this", "is", "test", "node", false) // "this" is the enodeId
    }).then(result => {
      assertEventOfType(result, "NewNodeProposed", 0)
    })
  })
  // Can only vote from voter accounts
  it('Can only vote from voter accounts', () => {
    return Permissions.deployed().then(instance => {
      permission = instance
      return permission.approveNode("this", {from: accounts[0]}) // "this" is the enodeId
    }).then(result => {
      assertEventOfType(result, "VoteNodeApproval", 0)
      return permission.approveNode("this", {from: accounts[1]})
    }).then(result => {
      assertEventOfType(result, "VoteNodeApproval", 0)
      assertEventOfType(result, "NodeApproved", 1)
    })
  })
  // Node approved after majority vote
})
