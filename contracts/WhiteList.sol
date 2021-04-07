pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ILaunchPad.sol";

interface INerdVault {
    function getRemainingLP(uint256 _pid, address _user)
        external
        view
        returns (uint256);
    function poolInfo(uint256 _pid) external view returns (IERC20, uint256, uint256, uint256, bool, uint256, uint256, uint256, uint256);

    function poolLength() external view returns (uint256);
}

interface INerdStaking {
    function getRemainingNerd(address _user) external view returns (uint256);
}

contract WhiteList is Ownable {
    using SafeMath for uint256;
    
    struct SnapshotInfo {
        address saleToken;
        uint256 saleId;
        uint256 timestamp;
        uint256[] farmedLPAmount;
        uint256[] nerdFarmedAmount; //compute nerd amount from farmed lp amount
        uint256 nerdStakedAmount;
    }

    //saleid => user address => snapshot
    mapping(uint256 => mapping(address => SnapshotInfo)) public userInfoSnapshot;
    mapping(uint256 => address[]) public whiteListeds;
    mapping(uint256 => uint256[2]) public whitelistTimeFrame; 

    IERC20 public nerd;
    INerdVault public vault;
    INerdStaking public staking;
    ILaunchPad public launchpad;

    constructor() public {
        vault = INerdVault(0x47cE2237d7235Ff865E1C74bF3C6d9AF88d1bbfF);
        staking = INerdStaking(0x357ADa6E0da1BB40668BDDd3E3aF64F472Cbd9ff);
        nerd = IERC20(0x32C868F6318D6334B2250F323D914Bc2239E4EeE);
    }

    function setLaunchPad(address _lp) external onlyOwner {
        launchpad = ILaunchPad(_lp);
    }

    function setWhitelistTimeFrame(uint256 _saleId, uint256[2] memory times) public onlyOwner {
        require(times[0] < times[1], "invalid times");
        whitelistTimeFrame[_saleId] = times;
    } 
    function whitelistMe(uint256 _saleId) external {
        require(whitelistTimeFrame[_saleId][0] <= block.timestamp && block.timestamp <= whitelistTimeFrame[_saleId][1], "out of time frame for whitelist");
        uint256 poolLength = vault.poolLength();
        if (userInfoSnapshot[_saleId][msg.sender].saleId == 0) {
            //initialize snapshot info
            userInfoSnapshot[_saleId][msg.sender].saleId = _saleId;
            userInfoSnapshot[_saleId][msg.sender].saleToken = launchpad.getSaleTokenByID(_saleId);
            userInfoSnapshot[_saleId][msg.sender].farmedLPAmount = new uint256[](poolLength);
            userInfoSnapshot[_saleId][msg.sender].nerdFarmedAmount = new uint256[](poolLength);
            whiteListeds[_saleId].push(msg.sender);
        }

        userInfoSnapshot[_saleId][msg.sender].timestamp = block.timestamp;
        //get nerd staked amount
        userInfoSnapshot[_saleId][msg.sender].nerdStakedAmount = staking.getRemainingNerd(msg.sender);
        for(uint256 i = 0; i < poolLength; i++) {
            (IERC20 lpToken,,,,,,,,) = vault.poolInfo(i);
            userInfoSnapshot[_saleId][msg.sender].farmedLPAmount[i] = vault.getRemainingLP(i, msg.sender);
            uint256 lpSupply = lpToken.totalSupply();
            uint256 nerdBalance = nerd.balanceOf(address(lpToken));
            userInfoSnapshot[_saleId][msg.sender].nerdFarmedAmount[i] = userInfoSnapshot[_saleId][msg.sender].farmedLPAmount[i].mul(nerdBalance).div(lpSupply);
        }
    }

    function getUserSnapshotInfo(uint256 _saleId, address _user) public view returns (address, uint256, uint256, uint256[] memory, uint256[] memory, uint256) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        return (info.saleToken, info.saleId, info.timestamp, info.farmedLPAmount, info.nerdFarmedAmount, info.nerdStakedAmount);
    }

    function getFarmStakeState(uint256 _saleId, address _user) public view returns (uint256 farmed, uint256 staked) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        staked = info.nerdStakedAmount;
        for(uint256 i = 0; i < info.nerdFarmedAmount.length; i++) {
            farmed = farmed.add(info.nerdFarmedAmount[i]);
        }
    }

    function getWhitelisteds(uint256 _saleId) external view returns (address[] memory) {
        return whiteListeds[_saleId];
    }
}
