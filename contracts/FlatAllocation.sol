pragma solidity 0.6.12;

import "./interfaces/IAllocation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract FlatAllocation is IAllocation, Ownable {
	mapping(uint256 => uint256) public allocation;

	function setAllocation(uint256 _saleId, uint256 _allocation) public onlyOwner {
		allocation[_saleId] = _allocation;
	}

	function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        external override
        view
        returns (uint256) {
		return allocation[_saleId];
	}

	function getEstimatedAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId) external view override returns (uint256) {
		return allocation[_saleId];
	}
}