pragma solidity 0.6.12;

import "./interfaces/IAllocation.sol";
import "./interfaces/IWhiteList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INerdInterfaces.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; 

contract LinearAllocation is IAllocation, Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        external
        view
		override
        returns (uint256) {
		if (!whitelist.isWhitelistFinished(_saleId)) return 0;
		(uint256 farmed, uint256 staked, uint256 total,) = whitelist.getUserSnapshotDetails(_saleId, _user);
		
		uint256 userPoint = farmed*2 + staked;
		if (userPoint > whitelist.cappedNerdForWhitelist()) {
            userPoint = whitelist.cappedNerdForWhitelist(); //capped at 100 nerd
        }
		return userPoint.mul(_totalSale).div(total);
	}

	function getEstimatedAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        external
        view
		override
        returns (uint256) {
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

	function rescueToken(address _token, address payable _to) external onlyOwner {
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        }
    }
}