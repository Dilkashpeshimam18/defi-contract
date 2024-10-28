// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YieldFarm is Ownable {
    IERC20 public stakingToken;     // Token being staked
    IERC20 public rewardToken;      // Token being distributed as rewards

    uint256 public rewardRate;      // Reward rate per second per token staked
    uint256 public totalStaked;     // Total amount of staking tokens staked

    struct StakeInfo {
        uint256 amount;             // Amount staked by the user
        uint256 rewardDebt;         // Rewards debt used for tracking rewards
        uint256 lastUpdated;        // Last time the user's stake was updated
    }

    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public pendingRewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
    }

    // Stake tokens in the yield farm
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake zero tokens");

        // Calculate any pending rewards
        _updateReward(msg.sender);

        // Transfer staking tokens from the user to this contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        // Update user's stake information
        stakes[msg.sender].amount += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    // Withdraw staked tokens and any pending rewards
    function withdraw(uint256 _amount) external {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount >= _amount, "Insufficient staked amount");

        // Calculate any pending rewards
        _updateReward(msg.sender);

        // Update staked amount
        stakeInfo.amount -= _amount;
        totalStaked -= _amount;

        // Transfer the withdrawn amount back to the user
        stakingToken.transfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    // Claim accumulated rewards
    function claimReward() external {
        _updateReward(msg.sender);

        uint256 reward = pendingRewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        pendingRewards[msg.sender] = 0;

        // Transfer reward tokens to the user
        rewardToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Calculate and update rewards for a user
    function _updateReward(address _user) internal {
        StakeInfo storage stakeInfo = stakes[_user];

        if (stakeInfo.amount > 0) {
            uint256 accruedReward = ((block.timestamp - stakeInfo.lastUpdated) *
                stakeInfo.amount * rewardRate) / 1e18;

            pendingRewards[_user] += accruedReward;
            stakeInfo.rewardDebt += accruedReward;
        }

        stakeInfo.lastUpdated = block.timestamp;
    }

    // Update the reward rate (only owner can call)
    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    // Emergency function to allow the owner to withdraw remaining reward tokens
    function emergencyWithdrawRewards() external onlyOwner {
        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));
    }

    // Check the pending rewards for a user
    function pendingReward(address _user) external view returns (uint256) {
        StakeInfo storage stakeInfo = stakes[_user];
        if (stakeInfo.amount == 0) {
            return pendingRewards[_user];
        }

        uint256 accruedReward = ((block.timestamp - stakeInfo.lastUpdated) *
            stakeInfo.amount * rewardRate) / 1e18;

        return pendingRewards[_user] + accruedReward;
    }
}
