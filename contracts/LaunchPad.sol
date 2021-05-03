pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; 
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./TokenTransfer.sol";
import "./interfaces/IAllocation.sol";
import "./interfaces/ILaunchPad.sol";
import "./utils/ReentrancyGuard.sol";

interface IDecimal {
    function decimals() external view returns (uint8);
}

contract LaunchPad is Ownable, TokenTransfer, ReentrancyGuard, ILaunchPad {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //Vesting is added before some token is unlocked, basically nerd team should receive token from tokensale team
    //then nerd team add a new vesting to the token sale
    //users then call unlockToken function
    struct TokenSale {
        address token;
        address payable tokenOwner;
        uint256 totalSale;
        uint256 totalSold;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 ethPegged; //in usd decimal 6
        uint256 tokenPrice; //in usd decimal 6
        uint256[] vestingAmounts; //token vesting array => contain token percentage
        uint256[] vestingPercentsX10; //token vesting array => contain token percentage
        uint256[] vestingClaimeds; //token vesting array => contain token percentage
        IAllocation allocation;
        bool needWhitelist;
    }

    struct UserInfo {
        uint256 alloc;
        uint256 bought;
        uint256 vestingPaidCount;   //count of vestings paid 
    }

    address public launchPadFund;
    uint256 public launchPadPercent;
    address[] public tokenList;
    //a token can have multiple sale: private, public ...
    mapping(address => uint256[]) public saleListForToken;
    mapping(address => bool) public allowedTokens;
    //saleid=>address=>user info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    TokenSale[] public allSales;
    /* 0: eth/bnb only
    *  1: usd only
    *  2: accept both
    */
    mapping(uint256 => uint256) public acceptedTokensType;
    IERC20 public usdContract;
    uint256 public usdDecimals;

    address public whitelistApprover;
    uint256 public chainId;

    constructor(address _signer, uint256 _chainId) public {
        whitelistApprover = _signer;
        chainId = _chainId;
    }

    modifier onlyTokenAllowed(address _token) {
        require(allowedTokens[_token], "!token not allowed");
        _;
    }

    modifier canBuyWithEthorBnb(uint256 _saleId) {
        require(acceptedTokensType[_saleId] != 1, "cannot buy with eth or bnb");
        _;
    }

    modifier canBuyWithUsd(uint256 _saleId) {
        require(acceptedTokensType[_saleId] != 0, "cannot buy with usd");
        _;
    }

    modifier onlyTokenOwner(uint256 _saleId) {
        require(allSales[_saleId].tokenOwner == msg.sender, "!token owner");
        _;
    }

    modifier onlyValidTime(uint256 _saleId) {
        require(
            allSales[_saleId].saleStart <= block.timestamp &&
                allSales[_saleId].saleEnd >= block.timestamp,
            "toke sale not valid time"
        );
        _;
    }

    function isFullAlloc(address _user, uint256 _saleId) public view returns (bool) {
        return userInfo[_saleId][_user].alloc <= userInfo[_saleId][_user].bought;
    }

    function getAllSalesLength() public view returns (uint256) {
        return allSales.length;
    }

    function setAllowedToken(address _token, bool _val) external onlyOwner {
        require(IERC20(_token).totalSupply() > 0, "!total supply");
        allowedTokens[_token] = _val;
    }

    function setAllocationAddress(uint256 _saleId, address _allocAddress) public onlyOwner {
        allSales[_saleId].allocation = IAllocation(_allocAddress);
    }

    function setUsdContract(address _addr) external onlyOwner {
        usdContract = IERC20(_addr);
        require(IDecimal(_addr).decimals() >= 6, "decimals cannot be lower than 6");
        usdDecimals = IDecimal(_addr).decimals();
    }

    function setAcceptedTokensType(uint256 _saleId, uint256 _type) public onlyOwner {
        acceptedTokensType[_saleId] = _type;
    }

    function setLaunchPad(address _addr, uint256 _percent) external onlyOwner {
        launchPadFund = _addr;
        launchPadPercent = _percent;
    }

    function setNeedWhitelist(uint256 _saleId, bool _need) external onlyOwner {
        allSales[_saleId].needWhitelist = _need;
    }

    function createTokenSale(
        address _token,
        address payable _tokenOwner,
        uint256 _amount,
        uint256 _start,
        uint256 _end,
        uint256 _ethPegged,
        uint256 _tokenPrice
    ) public onlyTokenAllowed(_token) onlyOwner {
        require(_end > _start && _start >= block.timestamp, "invalid params");

        uint256 saleId = allSales.length;
        saleListForToken[_token].push(saleId);
        
        TokenSale memory sale;
        sale.token = _token;
        sale.tokenOwner = _tokenOwner;
        sale.totalSale = _amount;
        sale.totalSold = 0;
        sale.saleStart = _start;
        sale.saleEnd = _end;
        sale.ethPegged = _ethPegged;
        sale.tokenPrice = _tokenPrice;

        allSales.push(sale);

        if (saleListForToken[_token].length == 1) {
            tokenList.push(_token);
        }
        emit NewTokenSale(_token, _tokenOwner, _amount, _start, _end, _ethPegged, _tokenPrice);
    }

    function createTokenSaleWithAllocation(
        address _token,
        address payable _tokenOwner,
        uint256 _amount,
        uint256 _start,
        uint256 _end,
        uint256 _ethPegged,
        uint256 _tokenPrice,
        address _allocationContract
    ) public onlyTokenAllowed(_token) onlyOwner {
        createTokenSale(_token, _tokenOwner, _amount, _start, _end, _ethPegged, _tokenPrice);
        setAllocationAddress(allSales.length - 1, _allocationContract);
    }

    function changeTotalSale(uint256 _saleId, uint256 _totalSale)
        external
        onlyOwner
    {
        //require(block.timestamp <= allSales[_saleId].saleEnd, "sale finish");
        allSales[_saleId].totalSale = _totalSale;
    }

    function changeTokenSaleStart(uint256 _saleId, uint256 _start)
        external
        onlyOwner
    {
        require(
            allSales[_saleId].saleStart > block.timestamp &&
                _start > block.timestamp,
            "sale already starts"
        );
        allSales[_saleId].saleStart = _start;
    }

    function changeTokenSaleEnd(uint256 _saleId, uint256 _end)
        external
        onlyOwner
    {
        // require(allSales[_saleId].saleEnd < _end, "sale already finish");
        // require(
        //     block.timestamp <= _end,
        //     "cannot release before token sale end"
        // );
        allSales[_saleId].saleEnd = _end;
    }

    function changeTokenSaleVesting(
        uint256 _saleId,
        uint256 _vestingIdx,
        uint256 _amount,
        uint256 _percentX10
    ) external onlyOwner {
        allSales[_saleId].vestingAmounts[_vestingIdx] = _amount;
        allSales[_saleId].vestingPercentsX10[_vestingIdx] = _percentX10;
    }

    function changeFundRecipient(uint256 _saleId, address payable _tokenOwner)
        external
        onlyOwner
    {
        allSales[_saleId].tokenOwner = _tokenOwner;
    }

    function addVesting(uint256 _saleId, uint256 _percentX10) public onlyOwner {
        //only add vesting if sale finishes
        require(block.timestamp > allSales[_saleId].saleEnd, "sale is not finished yet, dont know how much to distribute");
        require(_percentX10 <= 1000, "percent too high");
        uint256 _amount = allSales[_saleId].totalSold.mul(_percentX10).div(1000);
        
        safeTransferIn(allSales[_saleId].token, _amount);
        allSales[_saleId].vestingAmounts.push(_amount);
        allSales[_saleId].vestingPercentsX10.push(_percentX10);
        allSales[_saleId].vestingClaimeds.push(0);
        uint256 percentSum = 0;
        for(uint256 i = 0; i < allSales[_saleId].vestingPercentsX10.length; i++) {
            percentSum = percentSum.add(allSales[_saleId].vestingPercentsX10[i]);
        }
        require(percentSum <= 1000, "Percent total too high");
    }

    

    //eth or bnb
    function buyTokenWithEth(uint256 _saleId, bytes32[] memory rs, uint8 v)
        external
        payable
        canBuyWithEthorBnb(_saleId)
        nonReentrant
        onlyValidTime(_saleId)
    {
        bytes32 h = keccak256(abi.encode(msg.sender, address(this), chainId, _saleId, true));
        
        require(ecrecover(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", h)
        ), v, rs[0], rs[1]) == whitelistApprover, "invalid signature");

        uint256 calculatedAmount = msg.value.mul(allSales[_saleId].ethPegged).div(allSales[_saleId].tokenPrice);
        UserInfo storage user = userInfo[_saleId][msg.sender];
        user.alloc = getAllocation(msg.sender, allSales[_saleId].token, allSales[_saleId].totalSale, _saleId);
        require(user.alloc > 0, "no allocation");
        require(!isFullAlloc(msg.sender, _saleId), "buy over alloc");
        uint256 returnedEth = 0;
        uint256 actualSpent = msg.value;
        if (user.bought.add(calculatedAmount) > user.alloc) {
            calculatedAmount = user.alloc.sub(user.bought);
            actualSpent = calculatedAmount.mul(allSales[_saleId].tokenPrice).div(allSales[_saleId].ethPegged);
            returnedEth = msg.value.sub(actualSpent);
        }
        //ensure not over sold
        if (allSales[_saleId].totalSold.add(calculatedAmount) > allSales[_saleId].totalSale) {
            calculatedAmount = allSales[_saleId].totalSale.sub(allSales[_saleId].totalSold);
            actualSpent = calculatedAmount.mul(allSales[_saleId].tokenPrice).div(allSales[_saleId].ethPegged);
            returnedEth = msg.value.sub(actualSpent);
        }

        if (returnedEth > 0) {
            msg.sender.transfer(returnedEth);
        }
        allSales[_saleId].tokenOwner.transfer(actualSpent);
        user.bought = user.bought.add(calculatedAmount);
        allSales[_saleId].totalSold = allSales[_saleId].totalSold.add(calculatedAmount);
        emit TokenBuy(msg.sender, actualSpent, calculatedAmount);
    }

    function convertToEthWei(uint256 _amount, uint256 _ethPegged) public view returns (uint256) {
        return _amount.mul(1e18).div(10**(usdDecimals - 6)).div(_ethPegged);
    }

    function convertToUsd(uint256 _ethAmount, uint256 _ethPegged) public view returns (uint256) {
        return _ethAmount.mul(_ethPegged).mul(10**(usdDecimals - 6)).div(1e18);
    }

    function buyTokenWithUsd(uint256 _amount, uint256 _saleId, bytes32[] memory rs, uint8 v)
        external
        canBuyWithUsd(_saleId)
        nonReentrant
        onlyValidTime(_saleId)
    {
        //mathematically convert to eth/bnb
        uint256 msgvalue = convertToEthWei(_amount, allSales[_saleId].ethPegged);

        bytes32 h = keccak256(abi.encode(msg.sender, address(this), chainId, _saleId, true));
        
        require(ecrecover(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", h)
        ), v, rs[0], rs[1]) == whitelistApprover, "invalid signature");

        uint256 calculatedAmount = msgvalue.mul(allSales[_saleId].ethPegged).div(allSales[_saleId].tokenPrice);
        UserInfo storage user = userInfo[_saleId][msg.sender];
        user.alloc = getAllocation(msg.sender, allSales[_saleId].token, allSales[_saleId].totalSale, _saleId);
        require(user.alloc > 0, "no allocation");
        require(!isFullAlloc(msg.sender, _saleId), "buy over alloc");
        uint256 actualSpent = msgvalue;
        if (user.bought.add(calculatedAmount) > user.alloc) {
            calculatedAmount = user.alloc.sub(user.bought);
            actualSpent = calculatedAmount.mul(allSales[_saleId].tokenPrice).div(allSales[_saleId].ethPegged);
        }
        //ensure not over sold
        if (allSales[_saleId].totalSold.add(calculatedAmount) > allSales[_saleId].totalSale) {
            calculatedAmount = allSales[_saleId].totalSale.sub(allSales[_saleId].totalSold);
            actualSpent = calculatedAmount.mul(allSales[_saleId].tokenPrice).div(allSales[_saleId].ethPegged);
        }

        uint256 usdAmountSpent = convertToUsd(actualSpent, allSales[_saleId].ethPegged);
        require(usdAmountSpent <= _amount, "!math");
        
        usdContract.safeTransferFrom(msg.sender, allSales[_saleId].tokenOwner, usdAmountSpent);

        user.bought = user.bought.add(calculatedAmount);
        allSales[_saleId].totalSold = allSales[_saleId].totalSold.add(calculatedAmount);
        emit TokenBuy(msg.sender, usdAmountSpent, calculatedAmount);
    }

	function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId) public view returns (uint256) {
        return allSales[_saleId].allocation.getAllocation(_user, _token, _totalSale, _saleId);
    }

    function getEstimatedAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId) public view returns (uint256) {
        return allSales[_saleId].allocation.getEstimatedAllocation(_user, _token, _totalSale, _saleId);
    }

    function getUnlockableAmount(address _to, uint256 _saleId) public view returns (uint256) {
        uint256 ret = 0;
        UserInfo storage user = userInfo[_saleId][_to];
        for(uint256 i = user.vestingPaidCount; i < allSales[_saleId].vestingAmounts.length; i++) {
            uint256 toUnlock = allSales[_saleId].vestingPercentsX10[i].mul(user.bought).div(1000);
            ret = ret.add(toUnlock);
        }
        return ret;
    }

    function claimVestingToken(uint256 _saleId, address _to) external nonReentrant {
        UserInfo storage user = userInfo[_saleId][msg.sender];
        require(user.bought > 0, "nothing to claim");
        require(user.vestingPaidCount < allSales[_saleId].vestingAmounts.length, "already claim");
        uint256 ret = 0;
        for(uint256 i = user.vestingPaidCount; i < allSales[_saleId].vestingAmounts.length; i++) {
            uint256 toUnlock = allSales[_saleId].vestingPercentsX10[i].mul(user.bought).div(1000);
            ret = ret.add(toUnlock);
            allSales[_saleId].vestingClaimeds[i] = allSales[_saleId].vestingClaimeds[i].add(toUnlock);
        }
        uint256 claimFrom = user.vestingPaidCount;
        user.vestingPaidCount = allSales[_saleId].vestingAmounts.length;
        safeTransferOut(allSales[_saleId].token, _to, ret);
        emit TokenClaim(msg.sender, _to, _saleId, claimFrom, user.vestingPaidCount.sub(1), ret);
    }

    //get total already claimed token amount
    function getClaimedTokenAmount(uint256 _saleId, address _user) external view returns (uint256 ret) {
        ret = 0;
        UserInfo storage user = userInfo[_saleId][msg.sender];
        for(uint256 i = 0; i < user.vestingPaidCount; i++) {
            uint256 toUnlock = allSales[_saleId].vestingPercentsX10[i].mul(user.bought).div(1000);
            ret = ret.add(toUnlock);
        }
    }

    function getSaleById(uint256 _saleId)
        external
        view
        returns (
            address token,
            address tokenOwner,
            uint256[6] memory infos,
            uint256[] memory vestingAmounts,
            uint256[] memory vestingPercentsX10,
            uint256[] memory vestingClaimeds
        )
    {
        uint256 vestingsLength = allSales[_saleId].vestingAmounts.length;
        vestingAmounts = new uint256[](vestingsLength);
        vestingPercentsX10 = new uint256[](vestingsLength);
        vestingClaimeds = new uint256[](vestingsLength);

        for(uint256 i = 0; i < vestingsLength; i++) {
            vestingAmounts[i] = allSales[_saleId].vestingAmounts[i];
            vestingPercentsX10[i] = allSales[_saleId].vestingPercentsX10[i];
            vestingClaimeds[i] = allSales[_saleId].vestingClaimeds[i];
        }
        return (
            allSales[_saleId].token,
            allSales[_saleId].tokenOwner,
            [
                allSales[_saleId].totalSale,
                allSales[_saleId].totalSold,
                allSales[_saleId].saleStart,
                allSales[_saleId].saleEnd,
                allSales[_saleId].ethPegged,
                allSales[_saleId].tokenPrice
            ],
            vestingAmounts,
            vestingPercentsX10,
            vestingClaimeds
        );
    }

    function getTokenList() external view returns (address[] memory) {
        return tokenList;
    }

    function getSaleListForToken(address _token)
        external
        view
        returns (uint256[] memory)
    {
        return saleListForToken[_token];
    }

    function salesLength() external view returns (uint256) {
        return allSales.length;
    }

    function getSaleTokenByID(uint256 _saleId) external view override returns (address) {
        return allSales[_saleId].token;
    }

    function getSaleTimeFrame(uint256 _saleId) external view override returns (uint256, uint256) {
        return (allSales[_saleId].saleStart, allSales[_saleId].saleEnd);
    }

    function rescueToken(address _token, address payable _to) external onlyOwner {
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        }
    }

    mapping(address => bool) public payableWhitelist;
    receive() external payable {
        require(payableWhitelist[msg.sender], "not whitelist");
    }
    function setPayableWhitelist(address _addr, bool val) public onlyOwner {
        payableWhitelist[_addr] = val;
    }
}
