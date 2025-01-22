// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardsContract {
    // Mapping to store the user's reward balance
    mapping(address => uint256) public rewardBalances;

    // Mapping to store user's tier
    // (1 = Bronze, 2 = Silver, 3 = Gold, 4 = Platinum)
    mapping(address => uint256) public userTiers;

    // Total rewards distributed across all users
    uint256 public totalRewardsDistributed;

    // Events to emit when a reward is updated or claimed
    event RewardUpdated(address indexed user, uint256 newRewardBalance);
    event RewardClaimed(address indexed user, uint256 rewardAmount);

    // Function to update the user's reward based on their deposit and lock type
    // @param _user: The address of the user whose reward is being updated
    // @param _depositAmount: The amount of tokens deposited by the user
    // @param _lockType: The type of lock (0 - Flexible, 1 - Fractional, 2 - Time-Based, 3 - Fixed)

    function updateReward(address _user, uint256 _depositAmount, uint256 _lockType) external {
        
        // Determine the reward tier based on the lock type
        uint256 tier = determineTier(_lockType);

        // calculate the reward amount based on deposite amount
        uint256 rewardAmount = calculateReward(_depositAmount, tier);

        // increment user's reward balance with the newly calculated reward
        rewardBalances[_user] += rewardAmount;

        // update the total rewards distributed across all users    
        totalRewardsDistributed += rewardAmount;

        // emit an event to notify that users reward balance has been update
        emit RewardUpdated(_user, rewardBalances[_user]);

    }

    // Internal function to determine the user's reward tier based on the lock type
    // @param _lockType: The type of lock (0 - Flexible, 1 - Fractional, 2 - Time-Based, 3 - Fixed)
    // @return: The tier (1 - Bronze, 2 - Silver, 3 - Gold, 4 - Platinum)
    function determineTier(uint256 _lockType) internal pure returns (uint256) {
        if (_lockType == 0) return 1; // Flexible lock type maps to Bronze tier
        if (_lockType == 1) return 2; // Fractional lock type maps to Silver tier
        if (_lockType == 2) return 3; // Time-Based lock type maps to Gold tier
        if (_lockType == 3) return 4; // Fixed lock type maps to Platinum tier

        // If the lock type is invalid, revert the transaction
        revert("Invalid lock type");
    }

    // Internal function to calculate the reward based on the tier and deposit amount
    // @param _depositAmount: The amount of tokens deposited by the user
    // @param _tier: The reward tier (1 - Bronze, 2 - Silver, 3 - Gold, 4 - Platinum)
    // @return: The reward amount based on the deposit and the user's tier
    
    function calculateReward(uint256 _depositAmount, uint256 _tier) internal pure returns (uint256) {
        uint256 rewardRate;

        // Define the reward rate based on the user's tier
        if (_tier == 1) { // Bronze
            rewardRate = 5;  // 5% reward rate for Bronze tier
        } else if (_tier == 2) { // Silver
            rewardRate = 10; // 10% reward rate for Silver tier
        } else if (_tier == 3) { // Gold
            rewardRate = 15; // 15% reward rate for Gold tier
        } else if (_tier == 4) { // Platinum
            rewardRate = 20; // 20% reward rate for Platinum tier
        }

        // Calculate the reward by multiplying the deposit amount by the reward rate
        // and dividing by 100 to get the percentage value
        return (_depositAmount * rewardRate) / 100;
    }

     // Function to allow users to claim their rewards
    // The function transfers the accumulated rewards to the user's address
    function claimRewards() external {
        // Retrieve the reward balance of the caller (msg.sender)
        uint256 reward = rewardBalances[msg.sender];

        // Ensure that the user has rewards to claim
        require(reward > 0, "No rewards available");

        // Reset the user's reward balance to zero
        rewardBalances[msg.sender] = 0;

        // Transfer the reward amount to the user's address
        payable(msg.sender).transfer(reward);

        // Emit an event to notify that the user has claimed their reward
        emit RewardClaimed(msg.sender, reward);
    }

    // Function to get the current reward balance of the caller (msg.sender)
    // @return: The reward balance of the caller
    function getRewardBalance() external view returns (uint256) {
        // Return the reward balance of the caller
        return rewardBalances[msg.sender];
    }



}