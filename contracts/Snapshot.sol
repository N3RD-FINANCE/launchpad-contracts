pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/INerdInterfaces.sol";

contract Snapshot {
    using SafeMath for uint256;

    IERC20 public nerd;
    INerdVault public vault;
    INerdStaking public staking;

    constructor() public {
        vault = INerdVault(0x47cE2237d7235Ff865E1C74bF3C6d9AF88d1bbfF);
        staking = INerdStaking(0x357ADa6E0da1BB40668BDDd3E3aF64F472Cbd9ff);
        nerd = IERC20(0x32C868F6318D6334B2250F323D914Bc2239E4EeE);
    }       

    function isSnapshotStillValid(address _addr, uint256 _staked, uint256[] memory _farmedLPAmounts) public view returns (bool) {
        //validate snapshot
		if (staking.getRemainingNerd(_addr) < _staked) return false;

		uint256 poolLength = _farmedLPAmounts.length;
        for(uint256 i = 0; i < poolLength; i++) {
            if (_farmedLPAmounts[i] < vault.getRemainingLP(i, _addr)) return false;
        }
        return true;
    }

    function getNerdStaked(address _user) public view returns (uint256 staked, uint256 timestamp) {
        return (staking.getRemainingNerd(_user), block.timestamp);
    }

    function getNerdFarmed(address _user) public view returns (uint256 farmed, uint256[] memory farmedLPAmounts, uint256 timestamp) {
        uint256 poolLength = vault.poolLength();
        farmed = 0;
        farmedLPAmounts = new uint256[](poolLength);
        for(uint256 i = 0; i < poolLength; i++) {
            (IERC20 lpToken,,,,,,,,) = vault.poolInfo(i);
            farmedLPAmounts[i] = vault.getRemainingLP(i, _user);
            uint256 lpSupply = lpToken.totalSupply();
            uint256 nerdBalance = nerd.balanceOf(address(lpToken));
            uint256 nerdFarmedAmount = farmedLPAmounts[i].mul(nerdBalance).div(lpSupply);
            farmed = farmed.add(nerdFarmedAmount);
        }
        timestamp = block.timestamp;
    }

    function getSnapshot(address _user) external view returns (uint256[] memory amountsSnapshot, uint256 timestamp) {
        uint256 poolLength = vault.poolLength();
        amountsSnapshot = new uint256[](poolLength + 2);
        amountsSnapshot[0] = staking.getRemainingNerd(_user);

        uint256 farmed = 0;
        for(uint256 i = 0; i < poolLength; i++) {
            (IERC20 lpToken,,,,,,,,) = vault.poolInfo(i);
            amountsSnapshot[i + 2] = vault.getRemainingLP(i, _user);
            uint256 lpSupply = lpToken.totalSupply();
            uint256 nerdBalance = nerd.balanceOf(address(lpToken));
            uint256 nerdFarmedAmount = amountsSnapshot[i + 2].mul(nerdBalance).div(lpSupply);
            farmed = farmed.add(nerdFarmedAmount);
        }
        timestamp = block.timestamp;
        amountsSnapshot[1]  = farmed;
    }
}
