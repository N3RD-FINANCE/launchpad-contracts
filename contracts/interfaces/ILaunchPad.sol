pragma solidity ^0.6.12;

interface ILaunchPad {
	function getSaleTokenByID(uint256 _saleId) external view returns (address);
	function getSaleTimeFrame(uint256 _saleId) external view returns (uint256, uint256);

	event NewTokenSale(address indexed token, address indexed tokenOwner, uint256 indexed totalSale, uint256 start, uint256 end, uint256 ethPegged, uint256 tokenPrice);
	event TokenBuy(address indexed buyer, uint256 amount, uint256 tokenBought);
	event TokenClaim(address indexed claimer, address indexed recipient, uint256 saleId, uint256 from, uint256 to, uint256 amount);
}