// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardsContract.sol";


contract SavingsContract {
    // Address of the contract owner (who can modify certain parameters)
    address public owner;

    // The total amount the user aims to save for this goal
    uint public goalAmount;

    // Current balance saved so far
    uint public currentBalance;

    // Timestamp when the saving period starts
    uint public startDate;

    // Timestamp when the saving period ends (for time-based locking)
    uint public lockEndDate;

    // Limit for fractional withdrawals (used in Fractional Locking)
    uint public fractionalWithdrawalLimit;

    // Last contribution timestamp to track inactivity for reward adjustments
    uint public lastContributionTime;

    // The user's reward tier, calculated and managed by the Rewards Contract
    uint public rewardTier;

    // List of contributors for joint savings
    address[] public contributors;

    // Mapping to track the contributions of individual users
    mapping(address => uint) public balances;

    // Mapping to track if a user has claimed their rewards
    mapping(address => bool) public hasClaimedReward;

    // Link to the Rewards Contract
    RewardsContract public rewardsContract;

    // Numeric representation of the lock type (0 = Flexible, 1 = TimeBased, 2 = Fractional, 3 = Fixed)
    uint public lockType;

    // Events
    event ContributionMade(address indexed contributor, uint amount);
    event RewardClaimed(address indexed claimant, uint rewardAmount);
    event SavingsGoalReached(address indexed owner);


    // Modifier to restrict access to only the contract owner for specific functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }


     // Constructor to initialize the contract
    constructor(
        uint _goalAmount, 
        uint _startDate, 
        uint _lockEndDate, 
        uint _fractionalWithdrawalLimit, 
        address _rewardsContractAddress,
        uint _lockType
    ) {
        // Setting the contract owner
        owner = msg.sender;
        
        // Initialize the goal amount, start date, and end date
        goalAmount = _goalAmount;
        startDate = _startDate;
        lockEndDate = _lockEndDate;
        
        // Set fractional withdrawal limit (for fractional lock)
        fractionalWithdrawalLimit = _fractionalWithdrawalLimit;
        
        // Initialize the link to the Rewards Contract
        rewardsContract = RewardsContract(_rewardsContractAddress);
        
        // Set the lock type (0 = Flexible, 1 = TimeBased, 2 = Fractional, 3 = Fixed)
        lockType = _lockType;
        
        // Set the last contribution time (set to current time when contract is created)
        lastContributionTime = block.timestamp;
    }

    // Function to allow users to contribute funds to the savings plan
    function contribute(uint _amount) external payable {
        // Ensure that the sent amount matches the specified contribution
        require(msg.value == _amount, "Incorrect contribution amount");
        
        // Ensure that the current balance does not exceed the goal
        require(currentBalance + _amount <= goalAmount, "Goal amount already reached");

        // Add the contribution to the user's balance
        balances[msg.sender] += _amount;
        
        // Update the total current balance
        currentBalance += _amount;

        // If the contributor is new, add them to the list of contributors
        if (!hasContributor(msg.sender)) {
            contributors.push(msg.sender);
        }

        // Update reward tier and reward status for the contributor based on the contribution
        rewardsContract.updateReward(msg.sender, _amount, lockType);

        // Emit an event for this contribution
        emit ContributionMade(msg.sender, _amount);
        
        // Check if the savings goal has been reached
        if (currentBalance >= goalAmount) {
            emit SavingsGoalReached(owner);
        }


    }



    // Helper function to check if the contributor is already added to the contributors list
    function hasContributor(address contributor) internal view returns (bool) {
        for (uint i = 0; i < contributors.length; i++) {
            if (contributors[i] == contributor) {
                return true;
            }
        }
        return false;
    }


    // Function to allow withdrawal based on the chosen lock mechanism
    function withdraw(uint _amount) external {
        // Ensure that the user has enough balance to withdraw
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Check the type of lock and enforce the appropriate rules
        if (lockType == 0) {
            // Flexible withdrawals are allowed anytime
            _withdraw(msg.sender, _amount);
        } else if (lockType == 1) {
            // Time-based withdrawals require the current date to be after lockEndDate
            require(block.timestamp >= lockEndDate, "Withdrawal not allowed yet");
            _withdraw(msg.sender, _amount);
        } else if (lockType == 2) {
            // Fractional withdrawals have a limit on how much can be withdrawn at once
            require(_amount <= fractionalWithdrawalLimit, "Exceeds fractional withdrawal limit");
            _withdraw(msg.sender, _amount);
        } else if (lockType == 3) {
            // Fixed withdrawals only happen when the goal amount is reached or after lockEndDate
            require(block.timestamp >= lockEndDate || currentBalance >= goalAmount, "Withdrawal not allowed yet");
            _withdraw(msg.sender, _amount);
        }
    }

    // Internal function to handle the withdrawal process
    function _withdraw(address _user, uint _amount) internal {
        // Subtract the withdrawn amount from the user's balance
        balances[_user] -= _amount;

        // Transfer the withdrawn amount to the user
        payable(_user).transfer(_amount);
        
        // Update the reward status, as the user has claimed their reward
        hasClaimedReward[_user] = true;

        // Emit the reward claimed event
        emit RewardClaimed(_user, _amount);
    }


    // Function to allow the contract owner to change the savings goal amount
    function changeGoalAmount(uint _newGoalAmount) external onlyOwner {
        goalAmount = _newGoalAmount;
    }
}