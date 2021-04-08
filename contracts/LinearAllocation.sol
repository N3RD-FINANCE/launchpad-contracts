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
		(uint256 farmed, uint256 staked, uint256 total, uint256[] memory farmedLPAmount) = whitelist.getUserSnapshotDetails(_saleId, _user);
		
		//validate snapshot
		require(staking.getRemainingNerd(msg.sender) >= farmed, "validation for staking is invalid");

		uint256 poolLength = farmedLPAmount.length;
        for(uint256 i = 0; i < poolLength; i++) {
            require(vault.getRemainingLP(i, msg.sender) >= farmedLPAmount[i], "validation for farming is invalid");
        }

		uint256 userPoint = farmed*2 + staked;
		if (userPoint > 100e18) {
            userPoint = 100e18; //capped at 100 nerd
        }
		return userPoint.mul(_totalSale).div(total);
	}

	IWhiteList whitelist;

	IERC20 public nerd;
    INerdVault public vault;
    INerdStaking public staking;

    constructor() public {
        vault = INerdVault(0x47cE2237d7235Ff865E1C74bF3C6d9AF88d1bbfF);
        staking = INerdStaking(0x357ADa6E0da1BB40668BDDd3E3aF64F472Cbd9ff);
        nerd = IERC20(0x32C868F6318D6334B2250F323D914Bc2239E4EeE);
    }

	function setWhiteListContract(address _addr) public onlyOwner {
		whitelist = IWhiteList(_addr);
	}
}