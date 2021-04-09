pragma solidity 0.6.12;

interface IWhiteList {
	function getUserSnapshotDetails(uint256 _saleId, address _user) external view returns (uint256 farmed, uint256 staked, uint256 total, uint256[] memory farmedLPAmount);
	function isSnapshotStillValid(uint256 _saleId, address _addr) external view returns (bool);
}