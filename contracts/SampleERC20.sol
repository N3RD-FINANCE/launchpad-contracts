pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // for WETH

contract SampleERC20 is ERC20 {
    constructor(string memory tokenName, string memory symbol, address _mintTo) public ERC20(tokenName, symbol) {
        _mint(_mintTo, 1000000e18);
    }
}
