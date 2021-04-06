pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./TokenTransfer.sol";
import "./IAllocation.sol";
import "./utils/ReentrancyGuard.sol";

interface IDecimal {
    function decimals() external view returns (uint8);
}

contract LaunchPad is Ownable, TokenTransfer, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //Vesting is added before some token is unlocked, basically nerd team should receive token from tokensale team
    //then nerd team add a new vesting to the token sale
    //users then call unlockToken function
    struct TokenSale {
        address token;
        address tokenOwner;
        address payable fundRecipient;
        uint256 totalSale;
        uint256 totalSold;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 ethPegged; //in usd decimal 6
        uint256 tokenPrice; //in usd decimal 6
        uint256[] vestingAmounts; //token vesting array => contain token percentage
        uint256[] vestingPercentsX10; //token vesting array => contain token percentage
        uint256[] vestingClaimeds; //token vesting array => contain token percentage
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
    IAllocation public allocation;
    IERC20 public usdContract;

    modifier onlyTokenAllowed(address _token) {
        require(allowedTokens[_token], "!token not allowed");
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

    modifier onlyNotFullAlloc(uint256 _saleId) {
        require(
            userInfo[_saleId][msg.sender].alloc >
                userInfo[_saleId][msg.sender].bought,
            "already buy full alloc"
        );
        _;
    }

    function getAllSalesLength() public view returns (uint256) {
        return allSales.length;
    }

    function setAllowedToken(address _token, bool _val) external onlyOwner {
        require(IDecimal(_token).decimals() == 18, "!decimal 18");
        require(IERC20(_token).totalSupply() > 0, "!decimal 18");
        allowedTokens[_token] = _val;
    }

    function setAllocationAddress(address _allocAddress) external onlyOwner {
        allocation = IAllocation(_allocAddress);
    }

    function setUsdContract(address _addr) external onlyOwner {
        usdContract = IERC20(_addr);
    }

    function setLaunchPad(address _addr, uint256 _percent) external onlyOwner {
        launchPadFund = _addr;
        launchPadPercent = _percent;
    }

    // function validateVestingConfig(
    //     uint256 _unlockImmediatePercent,
    //     uint256[] memory _vestingTimes,
    //     uint256[] memory _vestingPercents
    // ) internal {
    //     require(
    //         _vestingTimes.length == _vestingPercents.length,
    //         "invalid vesting"
    //     );
    //     uint256 _totalPercent = _unlockImmediatePercent;
    //     for (uint256 i = 0; i < _vestingTimes.length; i++) {
    //         if (i > 0) {
    //             require(
    //                 _vestingTimes[i] > _vestingTimes[i - 1],
    //                 "invalid vesting time"
    //             );
    //         }
    //         _totalPercent = _totalPercent.add(_vestingPercents[i]);
    //     }
    //     require(_totalPercent == 100, "invalid vesting percent");
    // }

    function createTokenSale(
        address _token,
        address payable _fundRecipient,
        uint256 _amount,
        uint256 _start,
        uint256 _end,
        uint256 _ethPegged,
        uint256 _tokenPrice
    ) external onlyTokenAllowed(_token) nonReentrant onlyOwner {
        require(_end > _start && _start >= block.timestamp, "invalid params");

        uint256 saleId = allSales.length;
        saleListForToken[_token].push(saleId);
        
        TokenSale memory sale;
        sale.token = _token;
        sale.tokenOwner = msg.sender;
        sale.fundRecipient = _fundRecipient;
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
    }

    function changeTotalSale(uint256 _saleId, uint256 _totalSale)
        external
        nonReentrant
        onlyOwner
    {
        require(block.timestamp <= allSales[_saleId].saleEnd, "sale finish");
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
        require(allSales[_saleId].saleEnd < _end, "sale already finish");
        require(
            block.timestamp <= _end,
            "cannot release before token sale end"
        );
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

    function changeFundRecipient(uint256 _saleId, address payable _recipient)
        external
        onlyOwner
    {
        allSales[_saleId].fundRecipient = _recipient;
    }

    function addVesting(uint256 _saleId, uint256 _amount, uint256 _percentX10, bool _transferToken) public onlyOwner {
        allSales[_saleId].vestingAmounts.push(_amount);
        allSales[_saleId].vestingPercentsX10.push(_percentX10);
        allSales[_saleId].vestingClaimeds.push(0);

        if (_transferToken) {
            safeTransferIn(allSales[_saleId].token, _amount);
        }
    }


    //eth or bnb
    function buyTokenWithEth(uint256 _saleId)
        external
        payable
        nonReentrant
        onlyValidTime(_saleId)
        onlyNotFullAlloc(_saleId)
    {
        uint256 calculatedAmount = msg.value.mul(allSales[_saleId].ethPegged).div(allSales[_saleId].tokenPrice);
        UserInfo storage user = userInfo[_saleId][msg.sender];
        user.alloc = allocation.getAllocation(allSales[_saleId].token, _saleId);
        uint256 returnedEth = 0;
        if (user.bought.add(calculatedAmount) > user.alloc) {
            calculatedAmount = user.alloc.sub(user.bought);
            uint256 actualSpent = calculatedAmount.mul(allSales[_saleId].tokenPrice).div(allSales[_saleId].ethPegged);
            returnedEth = msg.value.sub(actualSpent);
        }
        if (returnedEth > 0) {
            msg.sender.transfer(returnedEth);
        }

        claimVestingToken(_saleId, msg.sender);
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

    function claimVestingToken(uint256 _saleId, address _to) public {
        UserInfo storage user = userInfo[_saleId][_to];
        require(user.bought > 0, "nothing to claim");
        require(user.vestingPaidCount < allSales[_saleId].vestingAmounts.length, "already claim");
        uint256 ret = 0;
        for(uint256 i = user.vestingPaidCount; i < allSales[_saleId].vestingAmounts.length; i++) {
            uint256 toUnlock = allSales[_saleId].vestingPercentsX10[i].mul(user.bought).div(1000);
            ret = ret.add(toUnlock);
            allSales[_saleId].vestingClaimeds[i] = allSales[_saleId].vestingClaimeds[i].add(toUnlock);
        }
        user.vestingPaidCount = allSales[_saleId].vestingAmounts.length;
        safeTransferOut(allSales[_saleId].token, _to, ret);
    }

    function buyTokenWithUsd(uint256 _saleId, uint256 _usdtAmount)
        external
        payable
        nonReentrant
        onlyValidTime(_saleId)
        onlyNotFullAlloc(_saleId)
    {
        revert();
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
}
