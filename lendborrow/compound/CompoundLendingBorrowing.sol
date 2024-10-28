pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICETH.sol";
import "./interfaces/ICERC20.sol";
import "./interfaces/IComptroller.sol";

contract CompoundLendingBorrowing {
    ICETH public cETH;
    ICERC20 public cDAI;
    IERC20 public dai;
    IComptroller public comptroller;
    address public owner;

    constructor(
        address _cETH,
        address _cDAI,
        address _dai,
        address _comptroller
    ) {
        cETH = ICETH(_cETH);
        cDAI = ICERC20(_cDAI);
        dai = IERC20(_dai);
        comptroller = IComptroller(_comptroller);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Supply ETH as collateral
    function supplyETH() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH to supply");

        // Mint cETH by sending ETH
        cETH.mint{value: msg.value}();
    }

    // Enter markets (enables the use of supplied collateral)
    function enterMarket() external onlyOwner {
        address;
        markets[0] = address(cETH);
        comptroller.enterMarkets(markets);
    }

    // Borrow DAI against the supplied ETH collateral
    function borrowDAI(uint256 _daiAmount) external onlyOwner {
        uint256 borrowResult = cDAI.borrow(_daiAmount);
        require(borrowResult == 0, "Borrowing DAI failed");
    }

    // Repay borrowed DAI
    function repayDAI(uint256 _daiAmount) external onlyOwner {
        require(dai.approve(address(cDAI), _daiAmount), "Approval failed");

        uint256 repayResult = cDAI.repayBorrow(_daiAmount);
        require(repayResult == 0, "Repaying DAI failed");
    }

    // Withdraw ETH collateral by redeeming cETH
    function withdrawETH(uint256 _cTokenAmount) external onlyOwner {
        uint256 redeemResult = cETH.redeem(_cTokenAmount);
        require(redeemResult == 0, "Redeeming cETH failed");
    }

    // Get the contract's DAI balance
    function getDAIBalance() external view returns (uint256) {
        return dai.balanceOf(address(this));
    }

    // Get the contract's ETH balance
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive ETH after redeeming cETH
    receive() external payable {}
}
