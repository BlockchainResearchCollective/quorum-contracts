pragma solidity ^0.4.23;

contract Permissions {

  // enum and struct declaration
  enum NodeStatus { NotInList, PendingApproval, Approved, PendingDeactivation, Deactivated, PendingBlacklisting, Blacklisted }
  enum AccountAccess { FullAccess, ReadOnly, Transact, ContractDeploy }
  struct NodeDetails {
    string enodeId; //e.g. 127.0.0.1:20005
    string ipAddrPort;
    string discPort;
    string raftPort;
    bool canLead;
    NodeStatus status;
  }
  struct AccountDetails {
    address accountAddress;
    AccountAccess accountAccess;
  }

  // use an array to store node details
  // if we want to list all node one day, mapping is not capable
  NodeDetails[] private nodeList;
  // use a mapping of enodeid to array index to track node
  mapping (bytes32 => uint) private nodeIdToIndex;
  // keep track of node number
  uint private numberOfNodes;

  // use an array to store account details
  // if we want to list all account one day, mapping is not capable
  AccountDetails[] private accountList;
  // use a mapping of account address to array index to track account
  mapping (address => uint) private accountAddressToIndex;
  // keep track of account number and voting account number
  uint private numberOfAccounts;
  uint private numberOfVotingAccounts;

  // store node approval, deactivation and blacklisting vote status (prevent double vote)
  mapping (uint => mapping (address => bool)) private voteStatus;
  // valid vote count
  mapping (uint => uint) private voteCount;

  // control initialization
  bool private initialized = false;

  // initialization event
  event ContractInitialized(uint _numberOfAccounts);
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
  event AccountAccessModified(address _accountAddress, AccountAccess _AccountAccess);

  modifier onlyAdmin()
  {
    require(
      accountAddressToIndex[msg.sender] != 0 &&
      accountList[accountAddressToIndex[msg.sender]].accountAccess == AccountAccess.FullAccess,
      "Sender not authorized"
    );
    _;
  }
  modifier mustInitialized()
  {
    require(initialized == true, "Contract not initialized, call initialize(uint, address[])");
    _;
  }
  modifier enodeInList(string _enodeId)
  {
    require(nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))] != 0, "Enode is not in the list");
    _;
  }
  modifier enodeNotInList(string _enodeId)
  {
    require(nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))] == 0, "Enode is in the list");
    _;
  }

  /* one time initialization function */

  function initialize(uint _numberOfAccounts, address[] _adminList)
    external
  {
    if (!initialized){
      accountList.push(AccountDetails(0x0, AccountAccess.ReadOnly)); // fake account
      nodeList.push(NodeDetails("zzy", "likes", "quorum", "!", true, NodeStatus.NotInList)); // fake node
      for (uint i = 0; i < _numberOfAccounts; i++){
        accountAddressToIndex[_adminList[i]] = i + 1; // use i + 1 because 0 is the default value for account doesn't exist
        accountList.push(AccountDetails(_adminList[i], AccountAccess.FullAccess));
      }
      numberOfAccounts = _numberOfAccounts;
      numberOfVotingAccounts = _numberOfAccounts;
      numberOfNodes = 0;
      initialized = true;
      emit ContractInitialized(numberOfAccounts);
    }
  }

  /* public and external functions */

  // view functions

  // Get number of nodes
  function getNumberOfNodes()
    public view
    returns (uint)
  {
    return numberOfNodes;
  }
  // Get number of accounts and voting accounts
  function getNumberOfAccounts()
    public view
    returns (uint, uint)
  {
    return (numberOfAccounts, numberOfVotingAccounts);
  }
  // Get node status by enode id
  function getNodeStatus(string _enodeId)
    public view
    enodeInList(_enodeId)
    returns (NodeStatus)
  {
    return nodeList[nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))]].status;
  }
  // Get account access by address
  function getAccountAccess(address _address)
    public view
    returns (AccountAccess)
  {
    if (accountAddressToIndex[_address] != 0){
      return accountList[accountAddressToIndex[_address]].accountAccess;
    } else {
      return AccountAccess.ReadOnly;
    }
  }
  // Get vote count by enode id
  function getVoteCount(string _enodeId)
    public view
    enodeInList(_enodeId)
    returns (uint)
  {
    return voteCount[nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))]];
  }
  // Get vote status by enode id and voter address
  function getVoteStatus(string _enodeId, address _voter)
    public view
    enodeInList(_enodeId)
    returns (bool)
  {
    return voteStatus[nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))]][_voter];
  }
  // for potential external use
  // Get enode id by index
  function getEnodeId(uint _index)
    external view
    returns (string)
  {
    if (_index <= numberOfNodes){
      return nodeList[_index].enodeId;
    } else {
      return "";
    }
  }
  // Get account address by index
  function getAccountAddress(uint _index)
    external view
    returns (address)
  {
    if (_index <= numberOfAccounts){
      return accountList[_index].accountAddress;
    } else {
      return address(0);
    }
  }
  // Get initialized
  function isInitialized()
    external view
    returns (bool)
  {
    return initialized;
  }

  // state change functions

  // propose a new node to the network
  function proposeNode(string _enodeId, string _ipAddrPort, string _discPort, string _raftPort, bool _canLead)
    external
    mustInitialized
    enodeNotInList(_enodeId)
  {
    // increment node number, add node to the list
    numberOfNodes++;
    nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))] = numberOfNodes;
    nodeList.push(NodeDetails(_enodeId, _ipAddrPort,_discPort, _raftPort, _canLead, NodeStatus.PendingApproval));
    // add voting status, numberOfNodes is the index of current proposed node
    for (uint i = 1; i <= numberOfAccounts; i++){
      voteStatus[numberOfNodes][accountList[i].accountAddress] = false;
    }
    voteCount[numberOfNodes] = 0;
    // emit event
    emit NewNodeProposed(_enodeId);
  }

  // Adds a node to the nodeList mapping and emits node added event if successfully and node exists event of node is already present
  function approveNode(string _enodeId)
    public
    mustInitialized
    onlyAdmin
  {
      require(getNodeStatus(_enodeId) == NodeStatus.PendingApproval, "Node need to be in PendingApproval status");
      uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
      require(voteStatus[nodeIndex][msg.sender] == false, "Node can not double vote");
      // vote node
      voteStatus[nodeIndex][msg.sender] = true;
      voteCount[nodeIndex]++;
      // emit event
      emit VoteNodeApproval(_enodeId, msg.sender);
      // check if node vote reach majority
      checkNodeApproval(_enodeId);
  }

  // Propose a node for deactivation from network
  function ProposeDeactivation(string _enodeId)
    public
    mustInitialized
    enodeInList(_enodeId)
  {
    require(getNodeStatus(_enodeId) == NodeStatus.Approved, "Node need to be in Approved status");
    uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
    nodeList[nodeIndex].status = NodeStatus.PendingDeactivation;
    // add voting status, numberOfNodes is the index of current proposed node
    for (uint i = 1; i <= numberOfAccounts; i++){
      voteStatus[nodeIndex][accountList[i].accountAddress] = false;
    }
    voteCount[nodeIndex] = 0;
    // emit event
    emit NodePendingDeactivation(_enodeId);
  }

  //deactivates a given Enode and emits the decativation event
  function DeactivateNode(string _enodeId)
    public
    mustInitialized
    onlyAdmin
  {
    require(getNodeStatus(_enodeId) == NodeStatus.PendingDeactivation, "Node need to be in PendingDeactivation status");
    uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
    require(voteStatus[nodeIndex][msg.sender] == false, "Node can not double vote");
    // vote node
    voteStatus[nodeIndex][msg.sender] = true;
    voteCount[nodeIndex]++;
    // emit event
    emit VoteNodeDeactivation(_enodeId, msg.sender);
    // check if node vote reach majority
    checkNodeDeactivation(_enodeId);
  }

  // Propose node for blacklisting
  function ProposeNodeBlacklisting(string _enodeId, string _ipAddrPort, string _discPort, string _raftPort)
    public
    mustInitialized
  {
    uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
    // check if node is in the nodeList
    if (nodeIndex != 0){
      // no matter what status the node is in, vote will reset and node status change to PendingBlacklisting
      nodeList[nodeIndex].status = NodeStatus.PendingBlacklisting;
    } else {
      // increment node number, add node to the list
      numberOfNodes++;
      nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))] = numberOfNodes;
      nodeIndex = numberOfNodes;
      nodeList.push(NodeDetails(_enodeId, _ipAddrPort,_discPort, _raftPort, false, NodeStatus.PendingBlacklisting));
    }
    // add voting status, numberOfNodes is the index of current proposed node
    for (uint i = 1; i <= numberOfAccounts; i++){
      voteStatus[nodeIndex][accountList[i].accountAddress] = false;
    }
    voteCount[nodeIndex] = 0;
    // emit event
    emit NodePendingBlacklisting(_enodeId);
  }

  //Approve node blacklisting
  function BlacklistNode(string _enodeId)
    public
    mustInitialized
    onlyAdmin
  {
    require(getNodeStatus(_enodeId) == NodeStatus.PendingBlacklisting, "Node need to be in PendingBlacklisting status");
    uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
    require(voteStatus[nodeIndex][msg.sender] == false, "Node can not double vote");
    // vote node
    voteStatus[nodeIndex][msg.sender] = true;
    voteCount[nodeIndex]++;
    // emit event
    emit VoteNodeBlacklisting(_enodeId, msg.sender);
    // check if node vote reach majority
    checkNodeBlacklisting(_enodeId);
  }

  // Checks if the Node is already added. If yes then returns true
  function updateAccountAccess(address _address, AccountAccess _accountAccess)
    external
    mustInitialized
    onlyAdmin
    {
      accountList.push(AccountDetails(_address, _accountAccess));
      numberOfAccounts++;
      accountAddressToIndex[_address] = numberOfAccounts;
      if (_accountAccess == AccountAccess.FullAccess){
        numberOfVotingAccounts++;
      }
      emit AccountAccessModified(_address, _accountAccess);
  }

  /* private functions */

  function checkNodeApproval(string _enodeId)
    internal
  {
    uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
    if (voteCount[nodeIndex] > numberOfVotingAccounts / 2){
      nodeList[nodeIndex].status = NodeStatus.Approved;
      emit NodeApproved(nodeList[nodeIndex].enodeId, nodeList[nodeIndex].ipAddrPort, nodeList[nodeIndex].discPort, nodeList[nodeIndex].raftPort);
    }
  }

  function checkNodeDeactivation(string _enodeId)
    internal
  {
    uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
    if (voteCount[nodeIndex] > numberOfVotingAccounts / 2){
      nodeList[nodeIndex].status = NodeStatus.Deactivated;
      emit NodeDeactivated(nodeList[nodeIndex].enodeId, nodeList[nodeIndex].ipAddrPort, nodeList[nodeIndex].discPort, nodeList[nodeIndex].raftPort);
    }
  }

  function checkNodeBlacklisting(string _enodeId)
    internal
  {
    uint nodeIndex = nodeIdToIndex[keccak256(abi.encodePacked(_enodeId))];
    if (voteCount[nodeIndex] > numberOfVotingAccounts / 2){
      nodeList[nodeIndex].status = NodeStatus.Blacklisted;
      emit NodeBlacklisted(nodeList[nodeIndex].enodeId, nodeList[nodeIndex].ipAddrPort, nodeList[nodeIndex].discPort, nodeList[nodeIndex].raftPort);
    }
  }

}
