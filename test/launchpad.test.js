const BN = require('bignumber.js');
BN.config({ DECIMAL_PLACES: 0 })
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN })
const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { inTransaction } = require('@openzeppelin/test-helpers/src/expectEvent');
const SampleERC20 = artifacts.require('SampleERC20');
const IERC20 = artifacts.require('IERC20');
const LaunchPad = artifacts.require('LaunchPad');
const FlatAllocation = artifacts.require('FlatAllocation');

const e18 = new BN('1000000000000000000');

const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
function toWei(n) {
    return new BN(n).multipliedBy(e18).toFixed();
}

function bn(x) {
    return new BN(x);
}

contract('Launchpad Test', (accounts) => {
	let deployer = accounts[0];
	let fundRecipient = accounts[1];
	let users = accounts.slice(2);
    beforeEach(async () => {
		this.sample = await SampleERC20.new(deployer)
		this.launchpad = await LaunchPad.new()
		await this.launchpad.setAllowedToken(this.sample.address, {from: deployer});

		const currentTime = await time.latest();
		//add new sale
		await this.launchpad.createTokenSale(this.sample.address, fundRecipient, toWei(1000000), currentTime, bn(currentTime).plus(1000).toFixed(0), bn(2000).multipliedBy(bn('1e6')).toFixed(0), bn(2).multipliedBy(bn('1e6')).toFixed(0));
		assert.equal('1', (await this.launchpad.salesLength()).valueOf().toString());

		const firstSale = (await this.launchpad.allSales(0)).valueOf();
		assert.equal(fundRecipient, firstSale.tokenOwner.toString());
	});

	it('Flat allocation', async () => {
		this.flatAlloc = await FlatAllocation.new(toWei(1000));
		await this.launchpad.setAllocationAddress(0, this.flatAlloc.address, {from: deployer});

		let tokenOwnerBalBefore = (await web3.eth.getBalance(fundRecipient)).valueOf().toString();
		await this.launchpad.buyTokenWithEth(0, {from: users[0], value: toWei(0.5)});
		let userInfo = (await this.launchpad.userInfo(0, users[0]).valueOf());
		assert.equal(toWei(1000), userInfo.alloc.toString())
		assert.equal(toWei(500), userInfo.bought.toString())
		let tokenOwnerBalAfter = (await web3.eth.getBalance(fundRecipient)).valueOf().toString();
		assert.equal(toWei(0.5), bn(tokenOwnerBalAfter).minus(tokenOwnerBalBefore).toFixed(0));

		tokenOwnerBalBefore = (await web3.eth.getBalance(fundRecipient)).valueOf().toString();
		await this.launchpad.buyTokenWithEth(0, {from: users[0], value: toWei(1)});
		userInfo = (await this.launchpad.userInfo(0, users[0]).valueOf());
		assert.equal(toWei(1000), userInfo.bought.toString())
		tokenOwnerBalAfter = (await web3.eth.getBalance(fundRecipient)).valueOf().toString();
		assert.equal(toWei(0.5), bn(tokenOwnerBalAfter).minus(tokenOwnerBalBefore).toFixed(0));

		await expectRevert(this.launchpad.buyTokenWithEth(0, {from: users[0], value: toWei(1)}), 'buy over alloc')

		await time.increase(1000);

		await expectRevert(this.launchpad.buyTokenWithEth(0, {from: users[1], value: toWei(1)}), 'toke sale not valid time')

		const sale = (await this.launchpad.allSales(0)).valueOf();
		assert.equal(toWei(1000), sale.totalSold.toString());
		//add vesting

		let balDeployerBefore = (await this.sample.balanceOf(deployer)).valueOf().toString();
		await this.sample.approve(this.launchpad.address, toWei(100000000), {from: deployer});
		await this.launchpad.addVesting(0, 200, {from: deployer});
		let balDeployerAfter = (await this.sample.balanceOf(deployer)).valueOf().toString();
		assert.equal(toWei(200), bn(balDeployerBefore).minus(balDeployerAfter).toFixed(0));

		//check claimable
		let claimable = (await this.launchpad.getUnlockableAmount(users[0], 0)).valueOf().toString();
		assert.equal(toWei(200), claimable);

		await this.launchpad.claimVestingToken(0, users[0]);
		assert.equal(toWei(200), (await this.sample.balanceOf(users[0])).valueOf().toString());

		claimable = (await this.launchpad.getUnlockableAmount(users[0], 0)).valueOf().toString();
		assert.equal(toWei(0), claimable);

		await expectRevert(this.launchpad.claimVestingToken(0, users[0]), 'already claim');
	});

	it('Add vesting', async () => {
	});
});