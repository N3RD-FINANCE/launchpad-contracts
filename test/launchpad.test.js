const BN = require('bignumber.js');
BN.config({ DECIMAL_PLACES: 0 })
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN })
const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { inTransaction } = require('@openzeppelin/test-helpers/src/expectEvent');
const SampleERC20 = artifacts.require('SampleERC20');
const IERC20 = artifacts.require('IERC20');
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

contract('Launchpad Test', (accounts) => {
	let deployer = accounts[0];
    beforeEach(async () => {
		this.sample = await SampleERC20.new(deployer)
		this.launchpad = await LaunchPad.new()
		await this.launchpad.setAllowedToken(this.sample.address, {from: deployer});
	});

	it('Deposit withdraw quit pool', async () => {
	});
});