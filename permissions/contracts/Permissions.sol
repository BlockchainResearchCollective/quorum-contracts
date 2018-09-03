pragma solidity ^0.4.23;

contract Permissions {

  // enum and struct declaration
  enum NodeStatus { PendingApproval, Approved, PendingDeactivation, Deactivated, PendingBlacklisting, Blacklisted }
  enum AccountAccess { ReadOnly, Admin, Transact, ContractDeploy }
  struct nodeDetails {
    string enodeId; //e.g. 127.0.0.1:20005
    string ipAddrPort;
    string discPort;
    string raftPort;
    bool canWrite; // this is strange, I think we should control the write permission at account level
    bool canLead;
    NodeStatus status;
  }
  struct accountDetails {
    address accountAddress
    AccountAccess accountAccess;
  }

  // use an array to store node details
  // if we want to list all node one day, mapping is not capable
  nodeDetails[] public nodeList;
  // use a mapping of enodeid to array index to track the node
  mapping (bytes32 => uint) public nodeIdList
  // keep track of node number
  uint public numberOfNodes;

  // use an array to store account details
  // if we want to list all account one day, mapping is not capable
  accountDetails[] public nodeList;
  // use a mapping of enodeid to array index to track the node
  mapping (bytes32 => uint) public nodeIdList
  // keep track of account number and votting account number
  uint public numberOfAccounts;
  uint public numberOfVottingAccounts;

  // store node approval, deactivation and blacklisting voting status
  mapping (uint => mapping (address => bool)) public votingStatus

  struct acctAccess {
    address acctId;
    AccountAccess access;
  }
  mapping (address => acctAccess) acctAccessList;

  // node permission events
  event NewNodeProposed(string _enodeId);
  event VoteNodeApproval(string _enodeId, address _accountAddress);
  event NodeApproved(string _enodeId, string _ipAddrPort, string _discPort, string _raftPort);
  event NodePendingDeactivation (string _enodeId);
  event VoteNodeDeactivation(string _enodeId, address _accountAddress);
  event NodeDeactivated(string _enodeId, string _ipAddrPort, string _discPort, string _raftPort);
  event NodePendingBlacklisting(string _enodeId);
  event VoteNodeBlacklisting(string _enodeId, address _accountAddress);
  event NodeBlacklisted(string _enodeId, string _ipAddrPort, string _discPort, string _raftPort);
  // account permission events
  event AcctAccessModified (address _accountAddress, AccountAccess _AccountAccess);

  /* public functions */

  // Checks if the Node is already added. If yes then returns true
  function getNodeStatus (string _enodeId) public view returns (NodeStatus _status) {
    return nodeList[keccak256(abi.encodePacked(_enodeId))].status;
  }

  // propose a new node to the network
  function ProposeNode(string _enodeId, bool _canWrite, bool _canLead, string _ipAddrPort, string _discPort, string _raftPort) public {
    require(getNodeStatus(_enodeId) == NodeStatus.NotInList, "New node cannot be in the list");
    nodeList[keccak256(abi.encodePacked(_enodeId))] = nodeDetails(_enodeId, _ipAddrPort,_discPort, _raftPort,  _canWrite, _canLead, NodeStatus.PendingApproval);
    emit NewNodeProposed (_enodeId);
  }

  // Adds a node to the nodeList mapping and emits node added event if successfully and node exists event of node is already present
  function ApproveNode(string _enodeId) public {
    require(getNodeStatus(_enodeId) == NodeStatus.PendingApproval);

    bytes32 i;
    i = keccak256(abi.encodePacked(_enodeId));
    nodeList[i].status = NodeStatus.Approved;
    emit NodeApproved(nodeList[i].enodeId, nodeList[i].ipAddrPort, nodeList[i].discPort, nodeList[i].raftPort);
  }

  // Propose a node for deactivation from network
  function ProposeDeactivation(string _enodeId) public {
    require(getNodeStatus(_enodeId) == NodeStatus.Approved, "Node need to be in Approved status");
    nodeList[keccak256(abi.encodePacked(_enodeId))].status = NodeStatus.PendingDeactivation;
    emit NodePendingDeactivation(_enodeId);
  }

  //deactivates a given Enode and emits the decativation event
  function DeactivateNode (string _enodeId) public {
    require(getNodeStatus(_enodeId) == NodeStatus.PendingDeactivation, "Node need to be in PendingDeactivation status");
    bytes32 i;
    i = keccak256(abi.encodePacked(_enodeId));
    nodeList[i].status = NodeStatus.Deactivated;
    emit NodeDeactivated(nodeList[i].enodeId, nodeList[i].ipAddrPort, nodeList[i].discPort, nodeList[i].raftPort);
  }

  // Propose node for blacklisting
  function ProposeNodeBlacklisting(string _enodeId, string _ipAddrPort, string _discPort, string _raftPort) public {
    if (getNodeStatus(_enodeId) == NodeStatus.NotInList){
      nodeList[keccak256(abi.encodePacked(_enodeId))] = nodeDetails(_enodeId, _ipAddrPort,_discPort, _raftPort,  false, false, NodeStatus.PendingBlacklisting);
    }
    else {
      nodeList[keccak256(abi.encodePacked(_enodeId))].status = NodeStatus.PendingBlacklisting;
    }
    emit NodePendingBlacklisting (_enodeId);
  }

  //Approve node blacklisting
  function BlacklistNode (string _enodeId) public {
    require(getNodeStatus(_enodeId) == NodeStatus.PendingBlacklisting, "Node need to be in PendingBlacklisting status");
    bytes32 i;
    i = keccak256(abi.encodePacked(_enodeId));
    nodeList[i].status = NodeStatus.Blacklisted;
    emit NodeBlacklisted(nodeList[i].enodeId, nodeList[i].ipAddrPort, nodeList[i].discPort, nodeList[i].raftPort);
  }

  // Checks if the Node is already added. If yes then returns true
  function updateAcctAccess (address _acctId, AccountAccess access) public {
    acctAccessList[_acctId] = acctAccess(_acctId, access);
    emit AcctAccessModified(_acctId, access);
  }

  /* private functions */

}
