pragma solidity ^0.6.12;

interface ILaunchPad {
	function getSaleTokenByID(uint256 _saleId) external view returns (address);
}