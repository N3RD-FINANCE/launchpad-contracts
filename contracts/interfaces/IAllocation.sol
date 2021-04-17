pragma solidity 0.6.12;

interface IAllocation {
    function getAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId)
        external
        view
        returns (uint256);

    function getEstimatedAllocation(address _user, address _token, uint256 _totalSale, uint256 _saleId) external view returns (uint256);
}
