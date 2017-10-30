'use strict';

/* Add the dependencies you're testing */
const Token = artifacts.require('RadusToken');
const BigNumber = web3.BigNumber
//
// YOUR CODE HERE

contract('TokenTest', function(accounts) {
	/* Define your constant variables and instantiate constantly changing
	 * ones
	 */
	let token = null;
	let expectedTokenSupply = new BigNumber(900);
	const owner = accounts[0]
	// YOUR CODE HERE

	/* Do something before every `describe` method */
	beforeEach(async function() {
		token = await Token.new("Radus", "RAD", 18, expectedTokenSupply, {from: owner});
	});

	/* Tests for Token.sol */
	describe('Tests for Token.sol', function() {
		it("Sanity Check", async function() {
			const name = "Radus";
			assert.strictEqual(name, "Radus");
		});
		it("Creates a balance", async function() {
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
