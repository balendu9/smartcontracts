// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Minigames {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Track user's total winnings and losses
    mapping(address => uint256) public totalWon;
    mapping(address => uint256) public totalLost;

    constructor() {
        owner = msg.sender;
    }

    // Funds deposited by owner in the contract
    event FundsDeposited(address indexed sender, uint256 amount);
    function depositFunds() external payable onlyOwner {
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Random generator, common for all games
    function _getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), 
            block.prevrandao, 
            msg.sender
        )));
    }

    // --------------------- Slots Game ---------------------

    string[6] public symbols = ["1", "2", "3", "4", "5", "6"];
    uint256 public minimumBet = 0.01 ether;

    // Track user's winnings and losses in slots
    mapping(address => uint256) public slotsWon;
    mapping(address => uint256) public slotsLost;

    event SpinResult(address indexed player, string[3] result, bool isWinner, uint256 payout);

    function playSlotsGame() public payable {
        require(msg.value >= minimumBet, "Bet amount too low");

        uint256 randomness = _getRandomNumber();

        uint256 reel1 = randomness % symbols.length;
        uint256 reel2 = (randomness / symbols.length) % symbols.length;
        uint256 reel3 = (randomness / symbols.length**2) % symbols.length;

        string[3] memory result = [symbols[reel1], symbols[reel2], symbols[reel3]];
        bool isWinner = (reel1 == reel2 && reel2 == reel3);
        uint256 payout = isWinner ? msg.value * 10 : 0;

        if (isWinner) {
            require(address(this).balance >= payout, "Insufficient contract balance");
            slotsWon[msg.sender] += payout;
            totalWon[msg.sender] += payout;
            payable(msg.sender).transfer(payout);
        } else {
            slotsLost[msg.sender] += msg.value;
            totalLost[msg.sender] += msg.value;
        }

        emit SpinResult(msg.sender, result, isWinner, payout);
    }

    function getUserStatsForSlots(address user) public view returns (uint256 won, uint256 lost) {
        return (slotsWon[user], slotsLost[user]);
    }

    // --------------------- Mystery Box Game ---------------------

    mapping(address => uint256) public mysteryRewards;
    mapping(address => uint256) public mysterySpent;

    event BoxPlayed(address indexed player, uint256 amountPaid, uint256 reward);
    
    function playMysteryBox() external payable {
        require(msg.value > 0, "Amount must be greater than zero");

        uint256 amountPaid = msg.value;
        mysterySpent[msg.sender] += amountPaid;
        uint256 randomValue = _getRandomNumber();

        uint256 scaledRandom = randomValue % 100;
        uint256 reward;
        if (scaledRandom < 80) {
            reward = amountPaid * (25 + (scaledRandom % 75)) / 100; 
        } else {
            reward = amountPaid * (100 + (scaledRandom % 100)) / 100;
        }

        require(address(this).balance >= reward, "Contract out of funds");

        mysteryRewards[msg.sender] += reward;
        totalWon[msg.sender] += reward;

        if (reward < amountPaid) {
            totalLost[msg.sender] += (amountPaid - reward);
        }

        payable(msg.sender).transfer(reward);

        emit BoxPlayed(msg.sender, amountPaid, reward);
    }

    function getUserStatsForMystery(address player) external view returns (uint256 mysteryWon, uint256 mysteryLost) {
        mysteryWon = mysteryRewards[player];
        mysteryLost = mysterySpent[player] > mysteryRewards[player] ? mysterySpent[player] - mysteryRewards[player] : 0;
        return (mysteryWon, mysteryLost);
    }

    function getUserStats(address user) public view returns (uint256 won, uint256 lost) {
        return (totalWon[user], totalLost[user]);
    }
}
