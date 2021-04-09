pragma solidity 0.6.12;

import "./interfaces/IAllocation.sol";
import "./interfaces/IWhiteList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INerdInterfaces.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract LinearAllocationWithWhiteList is IAllocation, Ownable {
	using SafeMath for uint256;
	function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        external
        view
		override
        returns (uint256) {
		require(totalPoint[_saleId] >= sumOfPoints[_saleId], "invalid point");
		uint256 userPoint = userPoints[_saleId][_user];
		if (userPoint > 100e18) {
            userPoint = 100e18; //capped at 100 nerd
        }
		return userPoint.mul(_totalSale).div(totalPoint[_saleId]);
	}

	mapping(uint256 => mapping (address => uint256)) public userPoints;
	mapping(uint256 => uint256) public totalPoint;
	mapping(uint256 => uint256) public sumOfPoints;

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
}