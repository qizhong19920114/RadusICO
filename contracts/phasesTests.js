'use strict';

/* dependencies  */
const Phases = artifacts.require('Phases');
const DutchAuction = artifacts.require('DutchAuction');
const BigNumber = web3.BigNumber


contract('PhasesTests', function(accounts) {
	/* Defines constant variables and instantiates constantly changing
	 * ones
	 */
	let phaseNum = 0;
	let moneyCap = 10000000;
	let tokenCap = 1000000000;
	let genAuc;
	const owner = accounts[0];

	/* Do something before every `describe` method */
	beforeEach(async function() {
		phase = await Phases.new(new BigNumber(phaseNum), new BigNumber(moneyCap), new BigNumber(tokenCap));
		//phase = Phases.new();
		auction = await DutchAuction.new(accounts[1], 1194, moneyCap, tokenCap, 20, false);
	});

	/* Tests for Phases.sol */
	describe('Tests for Phases.sol', async function() {
		it("Creates a general auction", function() {
			//const x = await auction.calcTokenPrice();
			const num = await phase.phaseNumber();
			//const auc = await phase.generalAuction();
			genAuc = auc;
			assert.equal(result, phaseNum + 1);
			assert.equal(auc, auction);
		});
		it("Sets the money cap", async function() {
			//const cap = await phase.setMoneyCap();
			assert.equal(cap, moneyCap);
		});
		it("Determines the current exchange rate", async function() {
			//const exRate = await phase.createExchangeRate();
			let rate = await auction.calcTokenPrice();
			assert.equal(exRate, rate)
		});
		it("Initiates the auction", async function() {
			return Phases.deployed().then(function(instance){
				instance.initiateAuction(moneyCap, tokenCap, accounts)
			}).then(function(result){
				assert.equal(result, genAuc);
			})
		});
		it("Can send funds to the team", async function() {
			//const funds = await phase.sendFundsToTeam();
			var success = True;
			assert.equal(funds, success);
		});
		it("Sets the total number of tokens", async function() {
			//const tokens = await phase.setTotal();
			assert.equal(token, tokenCap / 10);
		});
	});
});
