
const Web3 = require('web3');
const web3 = new Web3();
var privateKey = "7cb0c2e9624b4090d213cfaf6cf090ef36687b064a39872d5c1d79a2cc1f66b6";
var address = "0x399640c741c38d2aa881ad06406d9fc433812f31";

module.exports = {
    signWhitelist: function (addr, contractAddress, chainId, _saleId, _amountsSnapshot) {
		const encoded = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256[]'], [addr, contractAddress, chainId, _saleId, _amountsSnapshot])
        let msgHash = web3.utils.sha3(encoded);
        return web3.eth.accounts.sign(msgHash, privateKey);
    },
    approver: address
}
