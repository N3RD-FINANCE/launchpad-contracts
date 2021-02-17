pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./TokenTransfer.sol";
import "./IAllocation.sol";
import "./utils/ReentrancyGuard.sol";

contract LaunchPad is Ownable, TokenTransfer, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
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
        uint256[] vestingTimes;
        uint256[] vestingPercents;
        uint256 unlockImmediatePercent;
    }

    struct UserInfo {
        uint256 alloc;
        uint256 bought;
        bool[] vestingPaids; //array length must be equal to length of vestingPercents
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

    function validateVestingConfig(
        uint256 _unlockImmediatePercent,
        uint256[] memory _vestingTimes,
        uint256[] memory _vestingPercents
    ) internal {
        require(
            _vestingTimes.length == _vestingPercents.length,
            "invalid vesting"
        );
        uint256 _totalPercent = _unlockImmediatePercent;
        for (uint256 i = 0; i < _vestingTimes.length; i++) {
            if (i > 0) {
                require(
                    _vestingTimes[i] > _vestingTimes[i - 1],
                    "invalid vesting time"
                );
            }
            _totalPercent = _totalPercent.add(_vestingPercents[i]);
        }
        require(_totalPercent == 100, "invalid vesting percent");
    }

    function depositTokenForSale(
        address _token,
        address payable _fundRecipient,
        uint256 _amount,
        uint256 _start,
        uint256 _end,
        uint256 _ethPegged,
        uint256 _tokenPrice,
        uint256 _unlockImmediatePercent,
        uint256[] memory _vestingTimes,
        uint256[] memory _vestingPercents
    ) external onlyTokenAllowed(_token) nonReentrant {
        require(_end > _start && _start >= block.timestamp, "invalid params");
        validateVestingConfig(
            _unlockImmediatePercent,
            _vestingTimes,
            _vestingPercents
        );
        if (_vestingTimes.length > 0) {
            require(
                _vestingTimes[0] > _end,
                "cannot release before token sale end"
            );
        }
        safeTransferIn(_token, _amount);
        uint256 saleId = allSales.length;
        saleListForToken[_token].push(saleId);
        allSales.push(
            TokenSale({
                token: _token,
                tokenOwner: msg.sender,
                fundRecipient: _fundRecipient,
                totalSale: _amount,
                totalSold: 0,
                saleStart: _start,
                saleEnd: _end,
                ethPegged: _ethPegged,
                tokenPrice: _tokenPrice,
                vestingTimes: _vestingTimes,
                vestingPercents: _vestingPercents,
                unlockImmediatePercent: _unlockImmediatePercent
            })
        );
        if (saleListForToken[_token].length == 1) {
            tokenList.push(_token);
        }
    }

    function addMoreTokenForSale(uint256 _saleId, uint256 _amount)
        external
        nonReentrant
        onlyTokenOwner(_saleId)
    {
        require(block.timestamp <= allSales[_saleId].saleEnd, "sale finish");
        safeTransferIn(allSales[_saleId].token, _amount);
        allSales[_saleId].totalSale = allSales[_saleId].totalSale.add(_amount);
    }

    function changeTokenSaleStart(uint256 _saleId, uint256 _start)
        external
        onlyTokenOwner(_saleId)
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
        onlyTokenOwner(_saleId)
    {
        require(allSales[_saleId].saleEnd < _end, "sale already finish");
        require(
            allSales[_saleId].vestingTimes[0] > _end,
            "cannot release before token sale end"
        );
        allSales[_saleId].saleEnd = _end;
    }

    function changeTokenSaleVesting(
        uint256 _saleId,
        uint256 _unlockImmediatePercent,
        uint256[] memory _vestingTimes,
        uint256[] memory _vestingPercents
    ) external onlyTokenOwner(_saleId) {
        require(
            allSales[_saleId].saleStart > block.timestamp,
            "sale already start"
        );
        allSales[_saleId].unlockImmediatePercent = _unlockImmediatePercent;
        allSales[_saleId].vestingTimes = _vestingTimes;
        allSales[_saleId].vestingPercents = _vestingPercents;
    }

    function changeFundRecipient(uint256 _saleId, address payable _recipient)
        external
        onlyTokenOwner(_saleId)
    {
        allSales[_saleId].fundRecipient = _recipient;
    }

    function buyTokenWithEth(uint256 _saleId)
        external
        payable
        nonReentrant
        onlyValidTime(_saleId)
        onlyNotFullAlloc(_saleId)
    {}

    function buyTokenWithUsd(uint256 _saleId, uint256 _usdtAmount)
        external
        payable
        nonReentrant
        onlyValidTime(_saleId)
        onlyNotFullAlloc(_saleId)
    {}

    function getSaleById(uint256 _saleId)
        external
        view
        returns (
            address token,
            address tokenOwner,
            uint256[6] memory infos,
            uint256[] memory vestingTimes,
            uint256[] memory vestingPercents,
            uint256 unlockImmediatePercent
        )
    {
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
            allSales[_saleId].vestingTimes,
            allSales[_saleId].vestingPercents,
            allSales[_saleId].unlockImmediatePercent
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
