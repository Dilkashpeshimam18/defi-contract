// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICERC20 {
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
}
