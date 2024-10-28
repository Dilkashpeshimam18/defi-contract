// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveLendingBorrowing {
    ILendingPoolAddressesProvider public provider;
    address public owner;

    // Stablecoin and collateral tokens (e.g., DAI for borrowing, WETH for collateral)
    IERC20 public dai;
    IERC20 public weth;

    constructor(
        address _provider,
        address _dai,
        address _weth
    ) {
        provider = ILendingPoolAddressesProvider(_provider);
        dai = IERC20(_dai);
        weth = IERC20(_weth);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Deposit collateral (WETH) into Aave
    function depositCollateral(uint256 _amount) external onlyOwner {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Approve the LendingPool contract to transfer the WETH tokens
        require(weth.approve(address(lendingPool), _amount), "Approval failed");

        // Deposit WETH as collateral
        lendingPool.deposit(address(weth), _amount, address(this), 0);
    }

    // Borrow DAI using the deposited WETH as collateral
    function borrowDAI(uint256 _amount) external onlyOwner {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Borrow DAI with interest rate mode 1 (stable) or 2 (variable)
        lendingPool.borrow(address(dai), _amount, 2, 0, address(this));
    }

    // Repay the borrowed DAI
    function repayDAI(uint256 _amount) external onlyOwner {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Approve the LendingPool contract to transfer the DAI tokens
        require(dai.approve(address(lendingPool), _amount), "Approval failed");

        // Repay DAI
        lendingPool.repay(address(dai), _amount, 2, address(this));
    }

    // Withdraw the deposited WETH collateral
    function withdrawCollateral(uint256 _amount) external onlyOwner {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Withdraw collateral
        lendingPool.withdraw(address(weth), _amount, address(this));
    }

    // Utility function to check DAI balance
    function getDAIBalance() external view returns (uint256) {
        return dai.balanceOf(address(this));
    }

    // Utility function to check WETH balance
    function getWETHBalance() external view returns (uint256) {
        return weth.balanceOf(address(this));
    }
}
