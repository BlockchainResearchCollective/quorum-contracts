### ClusterKeys

1. May reuse the checkIfVoterExists function in canVote
2. addVoter function takes the master org key as parameter, but checkIfVoterExists function treats that as a sub org key (raising exception in test case)
3. In line 199, new OrgDetail struct is created with parameter sequence of "_orgId, _morgId..."(master, sub...), but the definition of OrgDetail is "orgId, vorgId..."(sub, master...)



May add more test cases for detailed review...