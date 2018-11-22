var ClusterKeys  = artifacts.require("./ClusterKeys.sol");

module.exports = function(deployer) {
  deployer.deploy(ClusterKeys);
};
