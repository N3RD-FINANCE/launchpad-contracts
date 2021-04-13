pragma solidity 0.6.12;

import "./interfaces/IAllocation.sol";
import "./interfaces/IWhiteList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INerdInterfaces.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; 

//for IDO on  BSC, whitelist is done on ETH. The results are then pushed to this contract deployed on BSC
contract LinearAllocationWithWhiteList is IAllocation, Ownable, IWhiteList {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        public
        view
		override
        returns (uint256) {
		require(totalPoint[_saleId] >= sumOfPoints[_saleId], "invalid point");
		uint256 userPoint = userPoints[_saleId][_user];
		if (userPoint > cappedNerd) {
            userPoint = cappedNerd; //capped at 100 nerd
        }
		return userPoint.mul(_totalSale).div(totalPoint[_saleId]);
	}

	mapping(uint256 => mapping (address => uint256)) public userPoints;
	mapping(uint256 => uint256) public totalPoint;
	mapping(uint256 => uint256) public sumOfPoints;

	uint256 public minNerd = 1e18;
    uint256 public cappedNerd = 100e18;

	function setNerdAmounts(uint256 _min, uint256 _capped) public onlyOwner {
        minNerd = _min;
        cappedNerd = _capped;
    }

	function add(uint256 _saleId, address[] memory _users, uint256[] memory _points) public onlyOwner {
		require(_users.length == _points.length, "invalid inputs");
		uint256 temp = sumOfPoints[_saleId];
		for(uint256 i = 0; i < _users.length; i++) {
			temp = temp.add(_points[i]).sub(userPoints[_saleId][_users[i]]);
			userPoints[_saleId][_users[i]] = _points[i];
		}
		sumOfPoints[_saleId] = temp;
	}	

	function setTotalPoint(uint256 _saleId, uint256 _point) public onlyOwner {
		require(_point >= sumOfPoints[_saleId], "invalid point");
		totalPoint[_saleId] = _point;
	}

	function minNerdForWhitelist() external view override returns (uint256) {
        return minNerd;
    }

	function cappedNerdForWhitelist() external view override returns (uint256) {
        return cappedNerd;
    }

    function isWhitelisted(uint256 _saleId, address _user) public view override returns (bool) {
        return userPoints[_saleId][_user] > 0;
    }

	function getLinearAllocation(address _user, uint256 _totalSale, uint256 _saleId)
        external
        view
        override
        returns (uint256) {
		return getAllocation(_user, address(0), _totalSale, _saleId);
	}

	function getUserSnapshotDetails(uint256 _saleId, address _user) public view override returns (uint256 farmed, uint256 staked, uint256 total, uint256[] memory farmedLPAmount) {
		return (0, 0, 0, new uint256[](0));
	}

	function isSnapshotStillValid(uint256 _saleId, address _addr) public view override returns (bool) {
		return true;
	}

	function whitelistMe(uint256 _saleId, bool checkStake, bool checkFarm) external override {
	}

	function rescueToken(address _token, address payable _to) external onlyOwner {
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        }
    }
}