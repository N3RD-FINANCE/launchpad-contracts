/* global artifacts */
const LaunchPad = artifacts.require('LaunchPad')
const LinearAllocationWithWhiteList = artifacts.require('LinearAllocationWithWhiteList')

module.exports = function (deployer, network, accounts) {
  return deployer.then(async () => {
    const launchpad = await deployer.deploy(LaunchPad)
    console.log('launchpad\'s address ', launchpad.address)
    
    const whitelist = await deployer.deploy(LinearAllocationWithWhiteList)
    console.log('LinearAllocationWithWhiteList\'s address ', whitelist.address)
  })
}
