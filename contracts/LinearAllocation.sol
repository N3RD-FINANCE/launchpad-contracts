pragma solidity 0.6.12;

import "./interfaces/IAllocation.sol";
import "./interfaces/IWhiteList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INerdInterfaces.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract LinearAllocation is IAllocation, Ownable {
	using SafeMath for uint256;
	function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        external
        view
		override
        returns (uint256) {
		if (!whitelist.isSnapshotStillValid(_saleId, _user)) return 0;
		(uint256 farmed, uint256 staked, uint256 total,) = whitelist.getUserSnapshotDetails(_saleId, _user);
		
		uint256 userPoint = farmed*2 + staked;
		if (userPoint > whitelist.cappedNerdForWhitelist()) {
            userPoint = whitelist.cappedNerdForWhitelist(); //capped at 100 nerd
        }
		return userPoint.mul(_totalSale).div(total);
	}

	IWhiteList whitelist;

	function setWhiteListContract(address _addr) public onlyOwner {
		whitelist = IWhiteList(_addr);
	}
}