### Permissions (old version)
P2P will come first before contract level access control. Therefore, we will have a static node list in Quorum which will contain all permanent node. The new nodes adding into the network will be written into another list and controlled by this contract.
There is a one time function which will let user to add initial admin account list. The subsequent account permission and node status change will be controlled by this contract.

### Test Cases (old version)
1. Permissions can only be initialized once
2. After initialization, number of nodes, number of accounts and number of voting accounts should be correct
3. After initialization, we should be able to get account address by index
4. Anyone account can propose new node, new node will be in PendingApproval status
5. Only full access account can approve node, new node vote status and vote count should be correct
6. After half of the voting accounts vote, new node will be in Approved status
7. Only admin can add account and modify account access
8. Can get account access information based on account address
9. Anyone can propose node deactivation on existing node, node will be in PendingDeactivation status
10. Only full access account can approve deactivation. node vote status and vote count should be correct
11. After half of the voting accounts vote on deactivation, node will be in Deactivated status
12. Anyone can propose node blacklisting on existing node, node will be in PendingBlacklisting status
13. Only full access account can approve blacklisting. node vote status and vote count should be correct
14. After half of the voting accounts vote on blacklisting, node will be in blacklisted status

The final contract is going to be a part of permission enhancement release in Quorum
