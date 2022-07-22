const Vendor = artifacts.require("TokenVendor");
const Token = artifacts.require("OGG");
const ecommerce = artifacts.require("ECommerce");

module.exports = async function (deployer) {
  await deployer.deploy(Token,1000000);
  const instance1 = await Token.deployed();
  await deployer.deploy(ecommerce,instance1.address);
  await deployer.deploy(Vendor,instance1.address)
  const instance2 = await Vendor.deployed();
  await instance1.transfer(instance2.address,1000000);
  await instance1.transferOwnership(instance2.address);
  
};
