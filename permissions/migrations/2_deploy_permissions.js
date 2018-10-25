var Permissions  = artifacts.require("./NewPermissions.sol");

module.exports = function(deployer) {
  deployer.deploy(Permissions);
};
