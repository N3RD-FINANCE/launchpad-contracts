pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ILaunchPad.sol";
import "./interfaces/INerdInterfaces.sol";
import "./interfaces/IWhiteList.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; 

contract WhiteList is Ownable, IWhiteList {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct SnapshotInfo {
        uint256 saleId;
        uint256 timestamp;
        mapping(uint256 => uint256) farmedLPAmount;
        mapping(uint256 => uint256) nerdFarmedAmount; //compute nerd amount from farmed lp amount
        uint256 sumOfNerdFarmedAmount;
        uint256 nerdStakedAmount;
        uint256 poolLength;
    }

    //saleid => user address => snapshot
    mapping(uint256 => mapping(address => SnapshotInfo)) public userInfoSnapshot;
    mapping(uint256 => uint256) public totalNerd;
    mapping(uint256 => address[]) public whiteListeds;
    mapping(uint256 => uint256[2]) public whitelistTimeFrame; 

    uint256 public minNerd = 1e18;
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

    function whitelistMe(uint256 _saleId, bool checkStake, bool checkFarm) external override {
        require(whitelistTimeFrame[_saleId][0] <= block.timestamp && block.timestamp <= whitelistTimeFrame[_saleId][1], "out of time frame for whitelist");
        uint256 poolLength = vault.poolLength();
        SnapshotInfo storage userInfo = userInfoSnapshot[_saleId][msg.sender];
        if (userInfo.timestamp == 0) {
            //initialize snapshot info
            userInfoSnapshot[_saleId][msg.sender].saleId = _saleId;
            whiteListeds[_saleId].push(msg.sender);
        }
        if (userInfo.poolLength != poolLength) {
            userInfo.poolLength = poolLength;
        }

        uint256 previousNerdPoint = userInfo.nerdStakedAmount.add(userInfo.sumOfNerdFarmedAmount.mul(2));

        userInfo.timestamp = block.timestamp;
        uint256 newSumNerdFarmed = 0;
        //get nerd staked amount
        if (checkStake) {
            userInfo.nerdStakedAmount = staking.getRemainingNerd(msg.sender);
        }
        if (checkFarm) {
            for(uint256 i = 0; i < poolLength; i++) {
                (IERC20 lpToken,,,,,,,,) = vault.poolInfo(i);
                userInfo.farmedLPAmount[i] = vault.getRemainingLP(i, msg.sender);
                uint256 lpSupply = lpToken.totalSupply();
                uint256 nerdBalance = nerd.balanceOf(address(lpToken));
                userInfo.nerdFarmedAmount[i] = userInfo.farmedLPAmount[i].mul(nerdBalance).div(lpSupply);
                newSumNerdFarmed = newSumNerdFarmed.add(userInfo.nerdFarmedAmount[i]);
            }
        }

        userInfo.sumOfNerdFarmedAmount = newSumNerdFarmed;
        uint256 userNewPoint = userInfo.nerdStakedAmount.add(userInfo.sumOfNerdFarmedAmount.mul(2));
        require(userNewPoint >= minNerd, "at least 1 nerd to be eligible");
        if (userNewPoint > cappedNerd) {
            userNewPoint = cappedNerd; //capped at 100 nerd
        }
        //adjust total point
        totalNerd[_saleId] = totalNerd[_saleId].add(userNewPoint).sub(previousNerdPoint);
    }

    function isSnapshotStillValid(uint256 _saleId, address _addr) public view override returns (bool) {
        //validate snapshot
		if (staking.getRemainingNerd(_addr) < userInfoSnapshot[_saleId][_addr].nerdStakedAmount) return false;

		uint256 poolLength = userInfoSnapshot[_saleId][_addr].poolLength;
        for(uint256 i = 0; i < poolLength; i++) {
            if (userInfoSnapshot[_saleId][_addr].farmedLPAmount[i] < vault.getRemainingLP(i, _addr)) return false;
        }
        return true;
    }

    function getActualNerdStaked(address _user) external view returns (uint256) {
        return staking.getRemainingNerd(_user);
    }

    function getActualNerdFarmed(address _user) external view returns (uint256) {
        uint256 poolLength = vault.poolLength();
        uint256 newSumNerdFarmed = 0;
        for(uint256 i = 0; i < poolLength; i++) {
            (IERC20 lpToken,,,,,,,,) = vault.poolInfo(i);
            uint256 farmedLPAmount = vault.getRemainingLP(i, _user);
            uint256 lpSupply = lpToken.totalSupply();
            uint256 nerdBalance = nerd.balanceOf(address(lpToken));
            uint256 nerdFarmedAmount = farmedLPAmount.mul(nerdBalance).div(lpSupply);
            newSumNerdFarmed = newSumNerdFarmed.add(nerdFarmedAmount);
        }
        return newSumNerdFarmed;
    }

    function getUserSnapshotInfo(uint256 _saleId, address _user) public view returns (address, uint256, uint256, uint256[] memory, uint256[] memory, uint256) {
        SnapshotInfo storage info = userInfoSnapshot[_saleId][_user];
        uint256[] memory farmedLPAmount = new uint256[](info.poolLength);
        uint256[] memory nerdFarmedAmount = new uint256[](info.poolLength);
        for(uint256 i = 0; i < farmedLPAmount.length; i++) {
            farmedLPAmount[i] = info.farmedLPAmount[i];
            nerdFarmedAmount[i] = info.nerdFarmedAmount[i];
        }
        return (launchpad.getSaleTokenByID(_saleId), info.saleId, info.timestamp, farmedLPAmount, nerdFarmedAmount, info.nerdStakedAmount);
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
        farmedLPAmount = new uint256[](info.poolLength);
        for(uint256 i = 0; i < farmedLPAmount.length; i++) {
            farmedLPAmount[i] = info.farmedLPAmount[i];
        }
    }

    function getUserSnapshotPoints(uint256 _saleId, address _user) public view returns (uint256 userPoint, uint256 total) {
        total = totalNerd[_saleId];
        if (!isSnapshotStillValid(_saleId, _user)) {
            userPoint = 0;
        } else {
            userPoint = userInfoSnapshot[_saleId][_user].nerdStakedAmount.add(userInfoSnapshot[_saleId][_user].sumOfNerdFarmedAmount.mul(2));
            if (userPoint > cappedNerd) {
                userPoint = 100e18;
            }
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
            farmeds[m] = info.sumOfNerdFarmedAmount;
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
		if (userPoint > cappedNerd) {
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

    function rescueToken(address _token, address payable _to) external onlyOwner {
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        }
    }

    function isWhitelistFinished(uint256 _saleId) external view override returns (bool) {
        return whitelistTimeFrame[_saleId][1] > 0 && whitelistTimeFrame[_saleId][1] < block.timestamp;
    }
}
