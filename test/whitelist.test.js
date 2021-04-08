const BN = require('bignumber.js');
BN.config({ DECIMAL_PLACES: 0 })
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN })
const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { inTransaction } = require('@openzeppelin/test-helpers/src/expectEvent');
const SampleERC20 = artifacts.require('SampleERC20');
const IERC20 = artifacts.require('IERC20');
const WhiteList = artifacts.require('WhiteList');
const UniswapV2Router02 = artifacts.require('UniswapV2Router02');
const LaunchPad = artifacts.require('LaunchPad');

const e18 = new BN('1000000000000000000');

const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
function toWei(n) {
    return new BN(n).multipliedBy(e18).toFixed();
}

function bn(x) {
    return new BN(x);
}

contract('Whitelist Test', (accounts) => {
	let deployer = accounts[0];
	let fundRecipient = accounts[1];
	let users = accounts.slice(2);
    beforeEach(async () => {
		this.nerd = await IERC20.at('0x32C868F6318D6334B2250F323D914Bc2239E4EeE')
		this.router = await UniswapV2Router02.at('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D')
		this.weth = await IERC20.at((await this.router.WETH()).valueOf().toString());
		this.whitelist = await WhiteList.new();
		this.launchpad = await LaunchPad.new()
	});

	it('Flat allocation', async () => {
		
	});

	it('Add vesting', async () => {
	});
});