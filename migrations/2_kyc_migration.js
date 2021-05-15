var KYCContract = artifacts.require("Kyc");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(KYCContract);
};