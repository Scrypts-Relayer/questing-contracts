var Quest = artifacts.require("QuestManager");

module.exports = function(deployer) {
  deployer.deploy(Quest);
};