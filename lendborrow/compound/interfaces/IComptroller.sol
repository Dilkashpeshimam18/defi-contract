// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
}
