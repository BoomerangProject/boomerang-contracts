var BoomerangToken = artifacts.require("./BoomerangToken.sol");

const tokenUnit = 10 ** 18;
const oneBillion = 10 ** 9;
const maxTokens = 10 * oneBillion * tokenUnit;

contract('BoomerangToken', function(accounts) {
  it("Should put 10 Billion BOOM's into first account", function() {
    return BoomerangToken.deployed().then(function(instance) {
    	return instance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
    	assert.equal(balance.valueOf(), maxTokens, "10 Billion wasn't in the first account");
    });
  })
})