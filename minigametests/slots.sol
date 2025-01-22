// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SlotMachine {
    string[6] public symbols = ["1", "2", "3", "4", "5", "6"];
    uint256 public minimumBet = 0.01 ether;
    address public owner;

    // Track user's winnings and losses
    mapping(address => uint256) public totalWon;
    mapping(address => uint256) public totalLost;

    event SpinResult(address indexed player, string[3] result, bool isWinner, uint256 payout);
    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function spin() public payable {
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
            payable(msg.sender).transfer(payout);
            totalWon[msg.sender] += payout;
        } else {
            totalLost[msg.sender] += msg.value;
        }

        emit SpinResult(msg.sender, result, isWinner, payout);
    }

    function _getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp, 
            block.prevrandao, 
            msg.sender, 
            block.number
        )));
    }

    function getUserStats(address user) public view returns (uint256 won, uint256 lost) {
        return (totalWon[user], totalLost[user]);
    }

    function depositFunds() external payable onlyOwner {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        payable(owner).transfer(amount);
        emit FundsWithdrawn(owner, amount);
    }

    receive() external payable {}
}
