'use strict';

/* Add the dependencies you're testing */
const Token = artifacts.require('RadusToken');
const DutchAuction = artifacts.require('DutchAuction');
const BigNumber = web3.BigNumber
//
// YOUR CODE HERE

contract('AuctionTest', function(accounts) {
	/* Define your constant variables and instantiate constantly changing
	 * ones
	 */
	let token = null;
	let expectedTokenSupply = new BigNumber(900);
	const owner = accounts[0]
  let pf = new BigNumber(1);
  let mc = new BigNumber(10000000);
  let tc = new BigNumber(1000);
  let time = new BigNumber(100000090037);

	// YOUR CODE HERE

	/* Do something before every `describe` method */
	beforeEach(async function() {
    token = await Token.new("Radus", "RAD", 18, expectedTokenSupply, {from: owner});
    //auction = await DutchAuction.new(owner, pf, mc, tc, time, true);
	});

	/* Tests for Token.sol */
	describe('Tests for DutchAuction.sol', function() {
		it("Sanity Check", async function() {
      DutchAuction.deployed().then(function(instance) {
        console.log("Hello: ", instance);
        factor = instance.priceFactor();
      });
			const name = await token.name();
			assert.strictEqual(name, "Radus");
      //const factor = auction.priceFactor();
      assert.strictEqual(factor, pf);
		});
		it("Whitelisted", async function() {
      DutchAuction.deployed().then(function(instance) {
        instance.addInvestor(accounts[1]);
        instance.setup(Token.address);
        instance.startAuction();
        instance.bid({from: accounts[1], value: new BigNumber(9999999999999999999)});
        assert.throws(instance.bid({from: accounts[3], value: new BigNumber(999999999999999999)}));
      });
			const balance = await token.balanceOf.call(owner);
			//assert.strictEqual(balance.toNumber(), 0);
			const supply = await token.balanceOf.call(token.address);
			const total = await token.totalSupply();
			assert.strictEqual(balance.toNumber(), total.toNumber());
		});
		it("should transfer 100 to accounts[1]", async function() {
			//await token.transfer(accounts[1], 100, {from: owner})
			  let num = new BigNumber(100);
			  await token.transfer(accounts[1], num, {from: owner, gas: 100000});
    		const balance = await token.balanceOf(accounts[1]);
    		assert.strictEqual(balance.toNumber(), 100);
		});
		it("supports 0 transfers", async function() {
			assert(await token.transfer.call(accounts[1], 0, {from: owner}), 'zero-transfer has failed')
		});
		it("Contract allows owner to burn tokens", async function() {
			const { logs } = await token.burn(100, { from: owner })
		});
	});
});
