pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";

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
