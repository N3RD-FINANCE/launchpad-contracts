pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH

interface INerdStaking {
    function getRemainingNerd(address _user) external view returns (uint256);
}

interface INerdVault {
    function getRemainingLP(uint256 _pid, address _user)
        external
        view
        returns (uint256);
    function poolInfo(uint256 _pid) external view returns (IERC20, uint256, uint256, uint256, bool, uint256, uint256, uint256, uint256);

    function poolLength() external view returns (uint256);
}