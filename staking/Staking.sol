// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is Ownable {
    IERC20 public stakingToken;
    uint256 public rewardRate; // Reward tokens per second
    uint256 public totalStaked;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 reward;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    constructor(address _stakingToken, uint256 _rewardRate) {
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
    }

    // Stake tokens
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake zero tokens");

        // Update stake for the user
        Stake storage userStake = stakes[msg.sender];

        // Calculate any existing rewards
        if (userStake.amount > 0) {
            uint256 pendingReward = calculateReward(msg.sender);
            userStake.reward += pendingReward;
        }

        // Transfer staking tokens from the user to the contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        
        // Update staked amount and start time
        userStake.amount += _amount;
        userStake.startTime = block.timestamp;

        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    // Calculate reward for a given user based on their stake and duration
    function calculateReward(address _user) public view returns (uint256) {
        Stake memory userStake = stakes[_user];
        uint256 stakingDuration = block.timestamp - userStake.startTime;
        uint256 reward = (userStake.amount * rewardRate * stakingDuration) / 1e18;
        return reward;
    }

    // Withdraw staked tokens and rewards
    function withdraw() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No tokens staked");

        // Calculate final reward and reset stake
        uint256 reward = calculateReward(msg.sender) + userStake.reward;
        uint256 amount = userStake.amount;

        userStake.amount = 0;
        userStake.reward = 0;
        userStake.startTime = 0;

        totalStaked -= amount;

        // Transfer staked tokens and rewards to the user
        stakingToken.transfer(msg.sender, amount);
        stakingToken.transfer(msg.sender, reward);

        emit Withdrawn(msg.sender, amount, reward);
    }

    // Update reward rate (only owner can call)
    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    // Emergency withdrawal by owner (in case of issues)
    function emergencyWithdraw() external onlyOwner {
        stakingToken.transfer(owner(), stakingToken.balanceOf(address(this)));
    }
}
