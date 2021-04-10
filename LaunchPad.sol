// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/TokenTransfer.sol

pragma solidity ^0.6.12;




contract TokenTransfer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function safeTransferIn(address _token, uint256 _amount) internal {
        IERC20 t = IERC20(_token);
        uint256 balBefore = t.balanceOf(address(this));
        t.safeTransferFrom(msg.sender, address(this), _amount);
        require(
            _amount == t.balanceOf(address(this)).sub(balBefore),
            "safe token transfer invalid"
        );
    }

    function safeTransferOut(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        IERC20 t = IERC20(_token);
        uint256 balBefore = t.balanceOf(address(this));
        t.safeTransfer(_to, _amount);
        require(
            _amount == balBefore.sub(t.balanceOf(address(this))),
            "token transfer invalid"
        );
    }
}

// File: contracts/interfaces/IAllocation.sol

pragma solidity 0.6.12;

interface IAllocation {
    function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        external
        view
        returns (uint256);
}

// File: contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/LaunchPad.sol

pragma solidity ^0.6.12;








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

    function isFullAlloc(address _user, uint256 _saleId) public view returns (bool) {
        return userInfo[_saleId][_user].alloc <= userInfo[_saleId][_user].bought;
    }

    function getAllSalesLength() public view returns (uint256) {
        return allSales.length;
    }

    function setAllowedToken(address _token, bool _val) external onlyOwner {
        require(IDecimal(_token).decimals() == 18, "!decimal 18");
        require(IERC20(_token).totalSupply() > 0, "!decimal 18");
        allowedTokens[_token] = _val;
    }

    function setAllocationAddress(uint256 _saleId, address _allocAddress) public onlyOwner {
        allSales[_saleId].allocation = IAllocation(_allocAddress);
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
        address payable _tokenOwner,
        uint256 _amount,
        uint256 _start,
        uint256 _end,
        uint256 _ethPegged,
        uint256 _tokenPrice
    ) public onlyTokenAllowed(_token) nonReentrant onlyOwner {
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

    function changeFundRecipient(uint256 _saleId, address payable _tokenOwner)
        external
        onlyOwner
    {
        allSales[_saleId].tokenOwner = _tokenOwner;
    }

    function addVesting(uint256 _saleId, uint256 _percentX10) public onlyOwner {
        //only add vesting if sale finishes
        require(allSales[_saleId].saleEnd < block.timestamp, "Sales not finished yet");
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
    function buyTokenWithEth(uint256 _saleId)
        external
        payable
        nonReentrant
        onlyValidTime(_saleId)
    {
        uint256 calculatedAmount = msg.value.mul(allSales[_saleId].ethPegged).div(allSales[_saleId].tokenPrice);
        UserInfo storage user = userInfo[_saleId][msg.sender];
        user.alloc = allSales[_saleId].allocation.getAllocation(msg.sender, allSales[_saleId].token, allSales[_saleId].totalSale, _saleId);
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
        //claimVestingToken(_saleId, msg.sender);
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

    function claimVestingToken(uint256 _saleId, address _to) public nonReentrant {
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

    function salesLength() external view returns (uint256) {
        return allSales.length;
    }

    function getSaleTokenByID(uint256 _saleId) external view returns (address) {
        return allSales[_saleId].token;
    }

    function getSaleTimeFrame(uint256 _saleId) external view returns (uint256, uint256) {
        return (allSales[_saleId].saleStart, allSales[_saleId].saleEnd);
    }
}
