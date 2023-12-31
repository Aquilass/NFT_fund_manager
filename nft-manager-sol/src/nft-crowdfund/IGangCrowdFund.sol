// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

interface IGangCrowdFund {
    function invest() external payable returns (uint256);
    function investManagerWithdrawInvest(uint256 amount) external returns (uint256);
    function investManagerWithdrawRevenue() external returns (uint256);
}