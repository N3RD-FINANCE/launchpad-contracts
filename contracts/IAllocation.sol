pragma solidity 0.6.12;

interface IAllocation {
    function getAllocation(address _token, uint256 _saleId)
        external
        view
        returns (uint256);
}
