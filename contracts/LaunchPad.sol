pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./TokenTransfer.sol";
import "./IAllocation.sol";

contract LaunchPad is Ownable, TokenTransfer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct TokenSale {
        address token;
        address tokenOwner;
        uint256 totalSale;
        uint256 totalSold;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 lockPercent;
        uint256 ethPegged; //in usd decimal 6
        uint256 tokenPrice; //in usd decimal 6
    }
    address[] public tokenList;
    //a token can have multiple sale: private, public ...
    mapping(address => uint256[]) public saleListForToken;
    mapping(address => bool) public allowedTokens;
    TokenSale[] public allSales;
    IAllocation public allocation;

    modifier onlyTokenAllowed(address _token) {
        require(allowedTokens[_token], "!token not allowed");
        _;
    }

    function setAllowedToken(address _token, bool _val) external onlyOwner {
        allowedTokens[_token] = _val;
    }

    function setAllocationAddress(address _allocAddress) external onlyOwner {
        allocation = IAllocation(_allocAddress);
    }

    function depositTokenForSale(
        address _token,
        uint256 _amount,
        uint256 _start,
        uint256 _end,
        uint256 _lockPercent,
        uint256 _ethPegged,
        uint256 _tokenPrice
    ) external onlyTokenAllowed(_token) {
        require(
            _end > _start && _start >= block.timestamp && _lockPercent <= 100,
            "invalid params"
        );
        safeTransferIn(_token, _amount);
        uint256 saleId = allSales.length;
        saleListForToken[_token].push(saleId);
        allSales.push(
            TokenSale({
                token: _token,
                tokenOwner: msg.sender,
                totalSale: _amount,
                totalSold: 0,
                saleStart: _start,
                saleEnd: _end,
                lockPercent: _lockPercent,
                ethPegged: _ethPegged,
                tokenPrice: _tokenPrice
            })
        );
        if (saleListForToken[_token].length == 1) {
            tokenList.push(_token);
        }
    }

    function addMoreTokenForSale(uint256 _saleId, uint256 _amount) external {
        require(block.timestamp <= allSales[_saleId].saleEnd, "sale finish");
        safeTransferIn(allSales[_saleId].token, _amount);
        allSales[_saleId].totalSale = allSales[_saleId].totalSale.add(_amount);
    }

    function changeTokenSaleStart(uint256 _saleId, uint256 _start) external {
        require(
            allSales[_saleId].saleStart >= block.timestamp &&
                _start >= block.timestamp &&
                allSales[_saleId].tokenOwner == msg.sender,
            "sale already starts"
        );
        allSales[_saleId].saleStart = _start;
    }

    function changeTokenSaleEnd(uint256 _saleId, uint256 _end) external {
        require(allSales[_saleId].saleEnd <= _end, "sale already finish");
        allSales[_saleId].saleEnd = _end;
    }

    function buyTokenWithEth(uint256 _saleId) external payable {}

    function buyTokenWithUsdt(uint256 _saleId, uint256 _usdtAmount)
        external
        payable
    {}

    function getAllSales() external view returns (TokenSale[] memory) {
        return allSales;
    }

    function getTokenList() external view returns (address[] memory) {
        return tokenList;
    }

    function getSaleListForToken(address _token)
        external
        view
        returns (address[] memory)
    {
        return saleListForToken[_token];
    }
}
