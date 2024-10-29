const LoteInversion = artifacts.require("LoteInversion");

module.exports = function (deployer) {
  const priceFeedAddress = '0x001382149eBa3441043c1c66972b4772963f5D43';
  deployer.deploy(LoteInversion, priceFeedAddress,0);
};
