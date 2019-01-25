var Mintable = artifacts.require("Mintable");

module.exports = function(deployer) {
  deployer.deploy(Mintable);
};