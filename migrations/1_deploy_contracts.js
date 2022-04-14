const BMFlokiRouter = artifacts.require("BMFlokiRouter");

const { factory, WETH } = require('../secrets.json');

module.exports = async function (deployer) {
  await deployer.deploy(BMFlokiRouter, factory, WETH);
};