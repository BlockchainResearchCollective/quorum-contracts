## quorum-contracts
quorum precompiled contracts dev

# Permissions
P2P will come first before contract level access control. Therefore, we will have a static node list in Quorum which will contain all permanent node. The new nodes adding into the network will be written into another list and controlled by this contract.
There is a one time function which will let user to add initial admin account list. The following account permission will controlled by this contract.
