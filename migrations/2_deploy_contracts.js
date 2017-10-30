//var ERC223_Interface = artifacts.require("./ERC223.sol");
//var ERC223_Token = artifacts.require("./ERC223Token.sol");
var Receiver_Interface = artifacts.require("./Receiver.sol");
var Token = artifacts.require("./RadusToken.sol");
var Phases = artifacts.require("./Phases.sol");
var DutchAuction = artifacts.require("./DutchAuction.sol");

module.exports = function(deployer) {
  //deployer.deploy(ERC223_Interface);
  deployer.deploy(DutchAuction, '0xa495d04da93900ecc16b285d3db9cf2b115d23a8', 1194, 100000, 10000, 20, true);
  //deployer.deploy(ERC223_Token);
  deployer.deploy(Receiver_Interface);
  deployer.deploy(Token, "Radus", "RAD", 18, 10000000);
  deployer.deploy(Phases);
};
