# quorum-contracts
quorum precompiled contracts dev

1. Use an array and a mapping to store account and node list. In this way, All accounts/nodes can be easily tracked
2. The permission flag should pass in an admin account. That account address will be the only admin at set up added by constructor
3. Use private variables to force security. People can only modify permission states by calling function.
