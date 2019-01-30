var nft = artifacts.require("Mintable");

module.exports = function(deployer) {
  deployer.deploy(nft);
};