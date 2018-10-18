var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var BoomerangToken = artifacts.require("./BoomerangToken.sol");
var Boomerang = artifacts.require("./Boomerang.sol");


module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(BoomerangToken);
  // deployer.deploy(BoomerangToken).then(function() {
  // 	return deployer.deploy(Boomerang, BoomerangToken.address);
  // });
};
