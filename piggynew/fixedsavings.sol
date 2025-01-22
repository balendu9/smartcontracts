// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FixedLockingSavings {
    address public owner;
    IERC20 public savingsCoin; // The SVNG token (ERC20)
    
    uint256 public goalAmount;
    uint256 public totalContributed;
    uint256 public rewardPercentage = 20; // 20% reward
    uint256 public lockDate;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public rewardClaimed;

    event ContributionMade(address indexed contributor, uint256 amount);
    event RewardClaimed(address indexed claimant, uint256 reward);

    address private constant SVNG_TOKEN_ADDRESS = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    constructor(uint256 _goalAmount, uint256 _lockDuration) {
        owner = msg.sender;
        savingsCoin = IERC20(SVNG_TOKEN_ADDRESS); // Set the SVNG token address
        goalAmount = _goalAmount;
        lockDate = block.timestamp + _lockDuration; // Set the lock date based on the duration
    }

    function contribute() external payable {
        require(msg.value > 0, "Contribution must be greater than zero.");
        require(block.timestamp < lockDate, "No further contributions allowed after the lock date.");

        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;

        emit ContributionMade(msg.sender, msg.value);
    }

    function claimReward() external {
        require(block.timestamp >= lockDate, "Savings are still locked.");
        require(contributions[msg.sender] > 0, "No contributions found for this address.");
        require(!rewardClaimed[msg.sender], "Reward already claimed.");

        // Check if the goal has been reached
        require(totalContributed >= goalAmount, "Goal not reached yet.");

        uint256 reward = (contributions[msg.sender] * rewardPercentage) / 100;

        // Transfer the reward from the contract to the user in SVNG tokens
        require(savingsCoin.transfer(msg.sender, reward), "Reward transfer failed.");

        rewardClaimed[msg.sender] = true;
        emit RewardClaimed(msg.sender, reward);
    }

    // Function to withdraw the contributions in case the goal is not met (emergency function)
    function withdrawContributions() external {
        require(block.timestamp >= lockDate, "Funds are still locked.");
        require(totalContributed < goalAmount, "Goal has been reached. Withdrawal is not allowed.");

        uint256 contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contributions found.");

        contributions[msg.sender] = 0;
        totalContributed -= contributedAmount;

        // Refund the contributor in ETH
        payable(msg.sender).transfer(contributedAmount);
    }

    // Fallback function to accept ETH contributions
    receive() external payable {
        require(msg.value > 0, "Contribution must be greater than zero.");
        require(block.timestamp < lockDate, "No further contributions allowed after the lock date.");

        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;

        emit ContributionMade(msg.sender, msg.value);
    }
}