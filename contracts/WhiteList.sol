pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@openzeppelin/contracts/math/SafeMath.sol";

interface INerdVault {
    function getRemainingLP(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

interface INerdStaking {
    function getRemainingNerd(address _user) external view returns (uint256);
}

contract WhiteList {
    struct SnapshotInfo {
        address saleToken;
        uint256 saleId;
        uint256 timestamp;
        uint256 farmedLPAmount;
        uint256 nerdStakedAmount;
    }

    struct PoolInfoSnapshot {
        address lp;
        uint256 totalAmount;
    }

    //saleid => user address => snapshot
    mapping(uint256 => mapping(address => SnapshotInfo))
        public userInfoSnapshot;
    //sale id =>
    mapping(uint256 => mapping(address => PoolInfoSnapshot))
        public poolInfoSnapshot;
    IERC20 public nerd;
    INerdVault public vault;
    INerdStaking public staking;

    address[] public vaultLPList;

    function whitelistMe(uint256 saleId) external {}
}
