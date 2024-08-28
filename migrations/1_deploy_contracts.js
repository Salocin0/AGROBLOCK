const SimpleStamper = artifacts.require("SimpleStamper");

module.exports = function (deployer) {
  deployer.deploy(SimpleStamper);
};
