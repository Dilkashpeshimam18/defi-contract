// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICETH {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns (uint256);
}
