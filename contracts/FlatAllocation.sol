pragma solidity 0.6.12;

import "./IAllocation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract FlatAllocation is IAllocation, Ownable {
	uint256 public allocation;
	function setAllocation(uint256 _allocation) public onlyOwner {
		allocation = _allocation;
	}

	function getAllocation(address _token, uint256 _saleId)
        external override
        view
        returns (uint256) {
		return allocation;
	}
}