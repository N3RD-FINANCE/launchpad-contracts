/* global artifacts */
const LaunchPad = artifacts.require('LaunchPad')
const LinearAllocation = artifacts.require('LinearAllocation')
const WhiteList = artifacts.require('WhiteList')

module.exports = function (deployer, network, accounts) {
  return deployer.then(async () => {
    const launchpad = await deployer.deploy(LaunchPad)
    console.log('launchpad\'s address ', launchpad.address)
    
    const whitelist = await deployer.deploy(WhiteList)
    console.log('WhiteList\'s address ', whitelist.address)

    const linearAllocation = await deployer.deploy(LinearAllocation)
    await linearAllocation.setWhiteListContract(whitelist.address)
    console.log('linearAllocation\'s address ', linearAllocation.address)
  })
}
