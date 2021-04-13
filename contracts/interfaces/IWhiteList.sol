pragma solidity 0.6.12;

interface IWhiteList {
	function getUserSnapshotDetails(uint256 _saleId, address _user) external view returns (uint256 farmed, uint256 staked, uint256 total, uint256[] memory farmedLPAmount);
	function isSnapshotStillValid(uint256 _saleId, address _addr) external view returns (bool);
	function getLinearAllocation(address _user, uint256 _totalSale, uint256 _saleId) external
        view
        returns (uint256);
	function minNerdForWhitelist() external view returns (uint256);
	function cappedNerdForWhitelist() external view returns (uint256);
	function whitelistMe(uint256 _saleId, bool checkStake, bool checkFarm) external;
	function isWhitelisted(uint256 _saleId, address _user) external view returns (bool);
	function isWhitelistFinished(uint256 _saleId) external view returns (bool);
}