// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MysteryBox {
    address public owner; 
    
    mapping(uint256 => uint256[]) public rewards; // Rewards for each box type (1 = Bronze, 2 = Silver, 3 = Gold)
    mapping(uint256 => uint256[]) public probabilities; // Probabilities for each reward type (in basis points: 100 = 1%)

    mapping(address => uint256) public totalRewards;  // Tracks total rewards won by each player
    mapping(address => uint256) public totalSpent;    // Tracks total amount spent by each player

    event BoxPlayed(address indexed player, uint256 amountPaid, uint256 reward);
    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "MysteryBox: Not authorized");
        _;
    }

    modifier hasSufficientFunds(uint256 rewardAmount) {
        require(address(this).balance >= rewardAmount, "MysteryBox: Insufficient contract balance");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function play() external payable {
        require(msg.value > 0, "Amount must be greater than zero");

        uint256 amountPaid = msg.value; 

        // Track the total amount spent by the player
        totalSpent[msg.sender] += amountPaid;

        // Generate pseudo-random number
        uint256 randomValue = _getRandomNumber();

        // Calculate reward based on random value
        uint256 reward = _calculateReward(amountPaid, randomValue);

        require(address(this).balance >= reward, "Contract out of funds");

        // Track the total reward won by the player
        totalRewards[msg.sender] += reward;

        payable(msg.sender).transfer(reward);

        emit BoxPlayed(msg.sender, amountPaid, reward);
    }

    function _getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp, 
            block.prevrandao, 
            msg.sender,
            block.number
        )));
    }

    function _calculateReward(uint256 amountPaid, uint256 randomValue) private pure returns (uint256 reward) {
        uint256 scaledRandom = randomValue % 100;

        if (scaledRandom < 80) {
            reward = amountPaid * (25 + (scaledRandom % 75)) / 100; 
        } else {
            reward = amountPaid * (100 + (scaledRandom % 100)) / 100;
        }
        return reward;
    }

    function withdrawFunds(uint256 amount) external onlyOwner hasSufficientFunds(amount) {
        payable(owner).transfer(amount);
        emit FundsWithdrawn(owner, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

    function getUserStats(address player) external view returns (uint256 totalWon, uint256 totalLost) {
        totalWon = totalRewards[player];
        totalLost = totalSpent[player] > totalRewards[player] ? totalSpent[player] - totalRewards[player] : 0;
        return (totalWon, totalLost);
    }

    receive() external payable {}

}
