pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ILaunchPad.sol";
import "./interfaces/INerdInterfaces.sol";

contract WhiteList is Ownable {
    using SafeMath for uint256;
    
    struct SnapshotInfo {
        address saleToken;
        uint256 saleId;
        uint256 timestamp;
        uint256[] farmedLPAmount;
        uint256[] nerdFarmedAmount; //compute nerd amount from farmed lp amount
        uint256 sumOfNerdFarmedAmount;
        uint256 nerdStakedAmount;
    }

    //saleid => user address => snapshot
    mapping(uint256 => mapping(address => SnapshotInfo)) public userInfoSnapshot;
    mapping(uint256 => uint256) public totalNerd;
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
        (uint256 saleStart,) = launchpad.getSaleTimeFrame(_saleId);
        require(times[0] < times[1], "invalid times");
        require(times[1] < saleStart, "whitelist must finish before token sale start");
        whitelistTimeFrame[_saleId] = times;
    } 
    function whitelistMe(uint256 _saleId) external {
        require(whitelistTimeFrame[_saleId][0] <= block.timestamp && block.timestamp <= whitelistTimeFrame[_saleId][1], "out of time frame for whitelist");
        uint256 poolLength = vault.poolLength();
        if (userInfoSnapshot[_saleId][msg.sender].timestamp == 0) {
            //initialize snapshot info
            userInfoSnapshot[_saleId][msg.sender].saleId = _saleId;
            userInfoSnapshot[_saleId][msg.sender].saleToken = launchpad.getSaleTokenByID(_saleId);
            userInfoSnapshot[_saleId][msg.sender].farmedLPAmount = new uint256[](poolLength);
            userInfoSnapshot[_saleId][msg.sender].nerdFarmedAmount = new uint256[](poolLength);
            whiteListeds[_saleId].push(msg.sender);
        }

        uint256 previousNerdPoint = userInfoSnapshot[_saleId][msg.sender].nerdStakedAmount.add(userInfoSnapshot[_saleId][msg.sender].sumOfNerdFarmedAmount.mul(2));

        userInfoSnapshot[_saleId][msg.sender].timestamp = block.timestamp;
        uint256 newSumNerdFarmed = 0;
        //get nerd staked amount
        userInfoSnapshot[_saleId][msg.sender].nerdStakedAmount = staking.getRemainingNerd(msg.sender);
        for(uint256 i = 0; i < poolLength; i++) {
            (IERC20 lpToken,,,,,,,,) = vault.poolInfo(i);
            userInfoSnapshot[_saleId][msg.sender].farmedLPAmount[i] = vault.getRemainingLP(i, msg.sender);
            uint256 lpSupply = lpToken.totalSupply();
            uint256 nerdBalance = nerd.balanceOf(address(lpToken));
            userInfoSnapshot[_saleId][msg.sender].nerdFarmedAmount[i] = userInfoSnapshot[_saleId][msg.sender].farmedLPAmount[i].mul(nerdBalance).div(lpSupply);
            newSumNerdFarmed = newSumNerdFarmed.add(userInfoSnapshot[_saleId][msg.sender].nerdFarmedAmount[i]);
        }

        userInfoSnapshot[_saleId][msg.sender].sumOfNerdFarmedAmount = newSumNerdFarmed;

        //adjust total point
        totalNerd[_saleId] = totalNerd[_saleId].add(userInfoSnapshot[_saleId][msg.sender].nerdStakedAmount.add(userInfoSnapshot[_saleId][msg.sender].sumOfNerdFarmedAmount.mul(2))).sub(previousNerdPoint);
    }

    function getUserSnapshotInfo(uint256 _saleId, address _user) public view returns (address, uint256, uint256, uint256[] memory, uint256[] memory, uint256) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        return (info.saleToken, info.saleId, info.timestamp, info.farmedLPAmount, info.nerdFarmedAmount, info.nerdStakedAmount);
    }

    function getFarmStakeState(uint256 _saleId, address _user) public view returns (uint256 farmed, uint256 staked) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        staked = info.nerdStakedAmount;
        farmed = info.sumOfNerdFarmedAmount;
    }

    function getUserSnapshotDetails(uint256 _saleId, address _user) public view returns (uint256 farmed, uint256 staked, uint256 total, uint256[] memory farmedLPAmount) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        staked = info.nerdStakedAmount;
        farmed = info.sumOfNerdFarmedAmount;
        total = totalNerd[_saleId];
        farmedLPAmount = info.farmedLPAmount;
    }

    function getAllFarmStakeState(uint256 _saleId) public view returns (address[] memory users, uint256[] memory farmeds, uint256[] memory stakeds) {
        users = whiteListeds[_saleId];
        farmeds = new uint256[](users.length);
        stakeds = new uint256[](users.length);
        for(uint256 m = 0; m < users.length; m++) {
            address _user = users[m];
            SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
            stakeds[m] = info.nerdStakedAmount;
            uint256 farmed = 0;
            for(uint256 i = 0; i < info.nerdFarmedAmount.length; i++) {
                farmed = farmed.add(info.nerdFarmedAmount[i]);
            }
            farmeds[m] = farmed;
        }
    }

    function getWhitelisteds(uint256 _saleId) external view returns (address[] memory) {
        return whiteListeds[_saleId];
    }
}
