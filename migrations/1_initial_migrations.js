const Migrations = artifacts.require("Ebay");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};