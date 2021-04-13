/* global artifacts */
const LaunchPad = artifacts.require('LaunchPad')
const LinearAllocationWithWhiteList = artifacts.require('LinearAllocationWithWhiteList')
const { time } = require('@openzeppelin/test-helpers');
const SampleERC20 = artifacts.require('SampleERC20')
const BN = require('bignumber.js');
BN.config({ DECIMAL_PLACES: 0 })
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN })

module.exports = function (deployer, network, accounts) {
  return deployer.then(async () => {
    const launchpad = await deployer.deploy(LaunchPad)
    console.log('launchpad\'s address ', launchpad.address)
    
    const whitelist = await deployer.deploy(LinearAllocationWithWhiteList)
    console.log('LinearAllocationWithWhiteList\'s address ', whitelist.address)


    const token1 = await deployer.deploy(SampleERC20, accounts[0])
    await launchpad.setAllowedToken(token1.address, true)
    let currentTime = Math.round(Date.now()/1000)
    console.log('current time:', currentTime.toString())
    await launchpad.createTokenSaleWithAllocation(
      token1.address,
      accounts[0],
      '1000000000000000000000000',
      new BN(currentTime).plus(100).toFixed(0),
      new BN(currentTime).plus(200).toFixed(0),
      '2000000000',
      '100000',
      whitelist.address
    )
    console.log('current time:', currentTime.toString())

    //adding on-going
    const token2 = await deployer.deploy(SampleERC20, accounts[0])
    await launchpad.setAllowedToken(token2.address, true)
    currentTime = Math.round(Date.now()/1000)
    await launchpad.createTokenSaleWithAllocation(
      token2.address,
      accounts[0],
      '1000000000000000000000000',
      new BN(currentTime).plus(200).toFixed(0),
      new BN(currentTime).plus(1000000).toFixed(0),
      '2000000000',
      '100000',
      whitelist.address
    )
    console.log('current time:', currentTime.toString())

    //add upcoming
    const token3 = await deployer.deploy(SampleERC20, accounts[0])
    await launchpad.setAllowedToken(token3.address, true)
    currentTime = Math.round(Date.now()/1000)
    await launchpad.createTokenSaleWithAllocation(
      token3.address,
      accounts[0],
      '1000000000000000000000000',
      new BN(currentTime).plus(500000).toFixed(0),
      new BN(currentTime).plus(10000000).toFixed(0),
      '2000000000',
      '100000',
      whitelist.address
    )
  })
}
