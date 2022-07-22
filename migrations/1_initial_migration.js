const ecommerce = artifacts.require("ECommerce");

module.exports = async function (deployer) {

  await deployer.deploy(ecommerce);
 
 
  
};
