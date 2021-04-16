const BN = require('bignumber.js');
BN.config({ DECIMAL_PLACES: 0 })
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN })
const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { inTransaction } = require('@openzeppelin/test-helpers/src/expectEvent');
const SampleERC20 = artifacts.require('SampleERC20');
const IERC20 = artifacts.require('IERC20');
const WhiteList = artifacts.require('WhiteList');
const UniswapV2Router02 = artifacts.require('UniswapV2Router02');
const UniswapV2Factory = artifacts.require('UniswapV2Factory');
const LaunchPad = artifacts.require('LaunchPad');
const INerdVault = artifacts.require('INerdVault')
const INerdStaking = artifacts.require('INerdStaking')
const LinearAllocation = artifacts.require('LinearAllocation')
const Snapshot = artifacts.require('Snapshot')
const Signer = require('./signer')


const e18 = new BN('1000000000000000000');
let instance;

const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
function toWei(n) {
    return new BN(n).multipliedBy(e18).toFixed(0);
}

function bn(x) {
    return new BN(x);
}

async function buyNerd(acc) {
	let currentTime = await time.latest();
	await instance.router.swapExactETHForTokens(0, [instance.weth.address, instance.nerd.address], acc, bn(currentTime).plus(100).toFixed(0), {from: acc, value: toWei(20)});
}

async function buyNerdSmall(acc) {
	let currentTime = await time.latest();
	await instance.router.swapExactETHForTokens(0, [instance.weth.address, instance.nerd.address], acc, bn(currentTime).plus(100).toFixed(0), {from: acc, value: toWei(1)});
}

async function addLiquidityAndFarm(acc, nerdAmount) {
	let currentTime = await time.latest();
	await instance.nerd.approve(instance.router.address, toWei(1000000), {from: acc})
	await instance.router.addLiquidityETH(instance.nerd.address, nerdAmount, 0, 0, acc, bn(currentTime).plus(100).toFixed(0), {from: acc, value: toWei(3)});
	const bal = (await instance.pair.balanceOf(acc)).valueOf().toString()
	await instance.pair.approve(instance.vault.address, bal, {from: acc})
	await instance.vault.deposit(0, bal, {from: acc})
}

async function stake(acc, nerdAmount) {
	await instance.nerd.approve(instance.staking.address, nerdAmount, {from: acc})
	await instance.staking.deposit(nerdAmount, {from: acc})
}

contract('Whitelist Test', (accounts) => {
	let deployer = accounts[0];
	let fundRecipient = accounts[1];
	let users = accounts.slice(2);
	let approver = Signer.approver;
    beforeEach(async () => {
		this.nerd = await IERC20.at('0x32C868F6318D6334B2250F323D914Bc2239E4EeE')
		this.router = await UniswapV2Router02.at('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D')
		this.factory = await UniswapV2Factory.at((await this.router.factory()).valueOf().toString())
		this.weth = await IERC20.at((await this.router.WETH()).valueOf().toString());
		this.pair = await IERC20.at((await this.factory.getPair(this.nerd.address, this.weth.address)).valueOf().toString())
		this.vault = await INerdVault.at('0x47cE2237d7235Ff865E1C74bF3C6d9AF88d1bbfF')
		this.staking = await INerdStaking.at('0x357ADa6E0da1BB40668BDDd3E3aF64F472Cbd9ff')
		this.whitelist = await WhiteList.new(approver, 1337);
		this.launchpad = await LaunchPad.new(approver, 1337);
		this.sample = await SampleERC20.new(deployer)
		this.linear = await LinearAllocation.new();
		await this.linear.setWhiteListContract(this.whitelist.address, {from: deployer})
		await this.whitelist.setLaunchPad(this.launchpad.address, {from: deployer})
		this.snapshot = await Snapshot.at("0xfE72c5b590abD8bbbbc10bB2a2FF5389f3B36b5f")
		instance = this;
	});

	it('Whitelist, validate snapshot, unstake, snapshot validate invalid', async () => {
		await buyNerd(users[2])
		await buyNerd(users[2])
		await buyNerd(users[0])
		await buyNerd(users[1])
		await buyNerd(users[2])
		await buyNerd(users[2])
		await buyNerd(users[2])

		await stake(users[0], toWei(5))
		await addLiquidityAndFarm(users[0], toWei(5))

		await stake(users[1], toWei(10))
		await addLiquidityAndFarm(users[1], toWei(10))

		await stake(users[2], toWei(100))
		await addLiquidityAndFarm(users[2], toWei(30))


		//add new token sale
		let currentTime = await time.latest();
		await this.launchpad.setAllowedToken(this.sample.address, true)
		await this.launchpad.createTokenSaleWithAllocation(this.sample.address, fundRecipient, toWei(1000000), bn(currentTime).plus(1000).toFixed(0), bn(currentTime).plus(86400).toFixed(0), bn(2000).multipliedBy(bn('1e6')).toFixed(0), bn(0.001).multipliedBy(bn('1e6')).toFixed(0), this.linear.address);
		assert.equal('1', (await this.launchpad.salesLength()).valueOf().toString());

		await this.whitelist.setWhitelistTimeFrame(0, [currentTime, bn(currentTime).plus(900).toFixed(0)])

		let amountsSnapshot = (await this.snapshot.getSnapshot(users[3])).valueOf().amountsSnapshot
		let signature = Signer.signWhitelist(users[3], this.whitelist.address, 1337, 0, amountsSnapshot)

		await expectRevert(this.whitelist.whitelistMe(0, amountsSnapshot, [signature.r, signature.s], signature.v,  {from: users[3]}), "at least 1 nerd to be eligible")
		
		amountsSnapshot = (await this.snapshot.getSnapshot(users[4])).valueOf().amountsSnapshot
		signature = Signer.signWhitelist(users[4], this.whitelist.address, 1337, 0, amountsSnapshot)
		await expectRevert(this.whitelist.whitelistMe(0, amountsSnapshot, [signature.r, signature.s], signature.v,  {from: users[4]}), "at least 1 nerd to be eligible")
		signature = Signer.signWhitelist(users[5], this.whitelist.address, 1337, 0, amountsSnapshot)
		await expectRevert(this.whitelist.whitelistMe(0, amountsSnapshot, [signature.r, signature.s], signature.v,  {from: users[4]}), "invalid signature")

		for(var i = 3; i < 15; i++) {
			await buyNerd(users[i])

			await stake(users[i], toWei(1))
			await addLiquidityAndFarm(users[i], toWei(1))
		}

		amountsSnapshot = (await this.snapshot.getSnapshot(users[0])).valueOf().amountsSnapshot
		signature = Signer.signWhitelist(users[0], this.whitelist.address, 1337, 0, amountsSnapshot)
		await this.whitelist.whitelistMe(0, amountsSnapshot, [signature.r, signature.s], signature.v, {from: users[0]})
		amountsSnapshot = (await this.snapshot.getSnapshot(users[1])).valueOf().amountsSnapshot
		signature = Signer.signWhitelist(users[1], this.whitelist.address, 1337, 0, amountsSnapshot)
		await this.whitelist.whitelistMe(0, amountsSnapshot, [signature.r, signature.s], signature.v, {from: users[1]})
		amountsSnapshot = (await this.snapshot.getSnapshot(users[2])).valueOf().amountsSnapshot
		signature = Signer.signWhitelist(users[2], this.whitelist.address, 1337, 0, amountsSnapshot)
		await this.whitelist.whitelistMe(0, amountsSnapshot, [signature.r, signature.s], signature.v, {from: users[2]})
		

		for(var i = 3; i < 15; i++) {
			amountsSnapshot = (await this.snapshot.getSnapshot(users[i])).valueOf().amountsSnapshot
			signature = Signer.signWhitelist(users[i], this.whitelist.address, 1337, 0, amountsSnapshot)
			await this.whitelist.whitelistMe(0, amountsSnapshot, [signature.r, signature.s], signature.v, {from: users[i]})
		}

		const point2 = (await this.whitelist.getUserSnapshotPoints(0, users[2])).valueOf().userPoint.toString();
		assert.equal(toWei(100), point2)

		const point0 = (await this.whitelist.getUserSnapshotPoints(0, users[0])).valueOf().userPoint.toString();
		amountsSnapshot = (await this.snapshot.getSnapshot(users[0])).valueOf().amountsSnapshot
		const user0Staked = amountsSnapshot[0].toString()
		const user0Farmed = amountsSnapshot[1].toString()
		assert.equal(point0, bn(user0Farmed).multipliedBy(2).plus(user0Staked).toFixed(0))

		await time.increase(1000)
		//buying token
		//reading getUserSnapshotInfo
		let getUserSnapshotInfo = await this.whitelist.getUserSnapshotInfo(0, users[0])
		console.log('getUserSnapshotInfo:', getUserSnapshotInfo)
		signature = Signer.signValidationSnapshot(users[0], this.launchpad.address, 1337, 0)
		await this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[0], value: toWei(100)})
		await expectRevert(this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[0], value: toWei(100)}), "buy over alloc")

		signature = Signer.signValidationSnapshot(users[1], this.launchpad.address, 1337, 0)
		await this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[1], value: toWei(100)})
		await expectRevert(this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[1], value: toWei(100)}), "buy over alloc")

		signature = Signer.signValidationSnapshot(users[2], this.launchpad.address, 1337, 0)
		await this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[2], value: toWei(100)})
		await expectRevert(this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[2], value: toWei(100)}), "buy over alloc")

		for(var i = 3; i < 15; i++) {
			signature = Signer.signValidationSnapshot(users[i], this.launchpad.address, 1337, 0)
			await this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[i], value: toWei(100)})
			await expectRevert(this.launchpad.buyTokenWithEth(0, [signature.r, signature.s], signature.v, {from: users[i], value: toWei(100)}), "buy over alloc")
		}

		for(var i = 0; i < 15; i++) {
			assert.notEqual('0', (await this.launchpad.getAllocation(users[i], this.sample.address, toWei(1000000), 0)).valueOf().toString())
		}

		const totalSold = (await this.launchpad.allSales(0)).valueOf().totalSold.toString()
		const totalSale = (await this.launchpad.allSales(0)).valueOf().totalSale.toString()
		let expectedTotalSold = bn(0)
		for(var i = 0; i < 15; i++) {
			const user = (await this.launchpad.userInfo(0, users[i])).valueOf()
			assert.equal(user.alloc.toString(), user.bought.toString())

			expectedTotalSold = expectedTotalSold.plus(user.bought)
		}
		assert.equal(totalSold, expectedTotalSold.toFixed(0))
		assert.equal(true, bn(totalSale).comparedTo(totalSold) >= 0)

		//add new vesting
		await time.increase(86400)
		await this.sample.approve(this.launchpad.address, toWei(1000000), {from: deployer})
		await this.launchpad.addVesting(0, 200, {from: deployer})
		assert.equal(bn(totalSold).multipliedBy(20).dividedBy(100).toFixed(0), (await this.sample.balanceOf(this.launchpad.address)).valueOf().toString())

		for(var i = 0; i < 15; i++) {
			await this.launchpad.claimVestingToken(0, users[i], {from: users[i]})
			const user = (await this.launchpad.userInfo(0, users[i])).valueOf()

			assert.equal(bn(user.bought).multipliedBy(20).dividedBy(100).toFixed(0), (await this.sample.balanceOf(users[i])).valueOf().toString())
		}

		await this.launchpad.addVesting(0, 100, {from: deployer})

		for(var i = 0; i < 15; i++) {
			const balBefore = (await this.sample.balanceOf(users[i])).valueOf().toString()
			await this.launchpad.claimVestingToken(0, users[i], {from: users[i]})
			await expectRevert(this.launchpad.claimVestingToken(0, users[i], {from: users[i]}), "already claim")
			const balAfter = (await this.sample.balanceOf(users[i])).valueOf().toString()
			const user = (await this.launchpad.userInfo(0, users[i])).valueOf()

			assert.equal(bn(balAfter).minus(balBefore).toFixed(0), bn(user.bought).multipliedBy(10).dividedBy(100).toFixed(0))
		}
	});
});