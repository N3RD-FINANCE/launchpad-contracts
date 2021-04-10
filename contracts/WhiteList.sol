pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ILaunchPad.sol";
import "./interfaces/INerdInterfaces.sol";
import "./interfaces/IWhiteList.sol";

contract WhiteList is Ownable, IWhiteList {
    using SafeMath for uint256;
    
    struct SnapshotInfo {
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

    uint256 public minNerd = 5e18;
    uint256 public cappedNerd = 100e18;

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

    function setNerdAmounts(uint256 _min, uint256 _capped) public onlyOwner {
        minNerd = _min;
        cappedNerd = _capped;
    }

    function setWhitelistTimeFrame(uint256 _saleId, uint256[2] memory times) public onlyOwner {
        (uint256 saleStart,) = launchpad.getSaleTimeFrame(_saleId);
        require(times[0] < times[1], "invalid times");
        require(times[1] < saleStart, "whitelist must finish before token sale start");
        whitelistTimeFrame[_saleId] = times;
    } 
    function whitelistMe(uint256 _saleId) external override {
        require(whitelistTimeFrame[_saleId][0] <= block.timestamp && block.timestamp <= whitelistTimeFrame[_saleId][1], "out of time frame for whitelist");
        uint256 poolLength = vault.poolLength();
        if (userInfoSnapshot[_saleId][msg.sender].timestamp == 0) {
            //initialize snapshot info
            userInfoSnapshot[_saleId][msg.sender].saleId = _saleId;
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
        uint256 userNewPoint = userInfoSnapshot[_saleId][msg.sender].nerdStakedAmount.add(userInfoSnapshot[_saleId][msg.sender].sumOfNerdFarmedAmount.mul(2));
        require(userNewPoint >= 5e18, "at least 5 nerd to be eligible");
        if (userNewPoint > minNerd) {
            userNewPoint = cappedNerd; //capped at 100 nerd
        }
        //adjust total point
        totalNerd[_saleId] = totalNerd[_saleId].add(userNewPoint).sub(previousNerdPoint);
    }

    function isSnapshotStillValid(uint256 _saleId, address _addr) public view override returns (bool) {
        //validate snapshot
		if (staking.getRemainingNerd(_addr) < userInfoSnapshot[_saleId][_addr].nerdStakedAmount) return false;

		uint256 poolLength = userInfoSnapshot[_saleId][_addr].farmedLPAmount.length;
        for(uint256 i = 0; i < poolLength; i++) {
            if (vault.getRemainingLP(i, _addr) >= userInfoSnapshot[_saleId][_addr].farmedLPAmount[i]) return false;
        }
        return true;
    }

    function getUserSnapshotInfo(uint256 _saleId, address _user) public view returns (address, uint256, uint256, uint256[] memory, uint256[] memory, uint256) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        return (launchpad.getSaleTokenByID(_saleId), info.saleId, info.timestamp, info.farmedLPAmount, info.nerdFarmedAmount, info.nerdStakedAmount);
    }

    function getFarmStakeState(uint256 _saleId, address _user) public view returns (uint256 farmed, uint256 staked) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        staked = info.nerdStakedAmount;
        farmed = info.sumOfNerdFarmedAmount;
    }

    function getUserSnapshotDetails(uint256 _saleId, address _user) public view override returns (uint256 farmed, uint256 staked, uint256 total, uint256[] memory farmedLPAmount) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        staked = info.nerdStakedAmount;
        farmed = info.sumOfNerdFarmedAmount;
        total = totalNerd[_saleId];
        farmedLPAmount = info.farmedLPAmount;
    }

    function getUserSnapshotPoints(uint256 _saleId, address _user) public view returns (uint256 userPoint, uint256 total) {
        total = totalNerd[_saleId];
        if (!isSnapshotStillValid(_saleId, _user)) {
            userPoint = 0;
        } else {
            userPoint = userInfoSnapshot[_saleId][msg.sender].nerdStakedAmount.add(userInfoSnapshot[_saleId][msg.sender].sumOfNerdFarmedAmount.mul(2));
        }
    }

    function getUsersSnapshotPoints(uint256 _saleId, address[] memory _users) public view returns (uint256[] memory userPoints, uint256 total) {
        total = totalNerd[_saleId];
        userPoints = new uint256[](_users.length);
        for(uint256 i = 0; i < _users.length; i++) {
            (uint256 userPoint,) = getUserSnapshotPoints(_saleId, _users[i]);
            userPoints[i]= userPoint;
        }
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

    function getLinearAllocation(address _user, uint256 _totalSale, uint256 _saleId)
        external
        view
        override
        returns (uint256) {
		if (!isSnapshotStillValid(_saleId, _user)) return 0;
		(uint256 farmed, uint256 staked, uint256 total,) = getUserSnapshotDetails(_saleId, _user);
		
		uint256 userPoint = farmed*2 + staked;
		if (userPoint > minNerd) {
            userPoint = cappedNerd; //capped at 100 nerd
        }
		return userPoint.mul(_totalSale).div(total);
	}

    function minNerdForWhitelist() external view override returns (uint256) {
        return minNerd;
    }

	function cappedNerdForWhitelist() external view override returns (uint256) {
        return cappedNerd;
    }

    function isWhitelisted(uint256 _saleId, address _user) public view override returns (bool) {
        return userInfoSnapshot[_saleId][_user].timestamp > 0;
    }
}
