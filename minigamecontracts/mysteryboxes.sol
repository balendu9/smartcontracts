// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "witnet-solidity-bridge/contracts/interfaces/IWitnetRandomness.sol";


contract MysteryBox {
    address public owner; 
    // interface for the randomness provider
    IWitnetRandomness public randomnessProvider;
    
    mapping(uint256 => uint256[]) public rewards; // Rewards for each box type (1 = Bronze, 2 = Silver, 3 = Gold)
    mapping(uint256 => uint256[]) public probabilities; // Probabilities for each reward type (in basis points: 100 = 1%)

    
    event BoxPlayed(address indexed player, uint256 amountPaid, uint256 reward); //Logs when a player plays the game
    event FundsDeposited(address indexed sender, uint256 amount); //Logs when the owner deposits funds into the contract.
    event FundsWithdrawn(address indexed recipient, uint256 amount);  //Logs when the owner withdraws funds.

    modifier onlyOwner() {
        require(msg.sender == owner, "MysteryBox: Not authorized");
        _;
    }

    modifier hasSufficientFunds(uint256 rewardAmount) {
        require(address(this).balance >= rewardAmount, "MysteryBox: Insufficient contract balance");
        _;
    }


    constructor(address _randomnessProvider) {
        owner = msg.sender;
        randomnessProvider = IWitnetRandomness(_randomnessProvider);
    }

    function play() external payable {
        require(msg.value > 0, "Amount must be greater than zero");

        //get the amount from the user
        uint256 amountPaid = msg.value; 

        // request randomness from witnet
        uint256 randomValue = randomnessProvider.randomize();

        // reward based on random value
        uint256 reward = _calculateReward(amountPaid, randomValue);

        // check if the contract has funds
        require(address(this).balance >= reward, "Contract out of funds");
        // transfer to player
        payable(msg.sender).transfer(reward);

        emit BoxPlayed(msg.sender, amountPaid, reward);

    }


    function _calculateReward(uint256 amountPaid, uint256 randomValue) private pure returns (uint256 reward) {

        // scaling the randomValue ot percentage (0-99)

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

     receive() external payable {}

}