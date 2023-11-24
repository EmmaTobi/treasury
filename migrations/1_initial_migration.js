const Strategy = artifacts.require("Strategy");
const Treasury = artifacts.require("Treasury");
const TestAAVEProtocol = artifacts.require("TestAAVEProtocol");
const TestCurveProtocol = artifacts.require("TestCurveProtocol");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(TestAAVEProtocol);
  const aaveProtocol = await TestAAVEProtocol.deployed();

  await deployer.deploy(TestCurveProtocol);
  const curveProtocol = await TestCurveProtocol.deployed();
  
  await deployer.deploy(Strategy, [aaveProtocol.address, curveProtocol.address], [20, 50],  accounts[0]);

  const strategyInstance = await Strategy.deployed();

  await deployer.deploy(Treasury, strategyInstance.address);
};
