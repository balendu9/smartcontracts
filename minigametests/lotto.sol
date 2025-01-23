// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract LottoGame {
    address public owner;

    // Fee to play the game (e.g., 0.01 ether)
    uint256 public gameFee = 0.01 ether;

    // Events to log important actions
    event GamePlayed(address indexed player, uint8[6] userNumbers, uint8[6] winningNumbers, uint256 reward);
    event FundsDeposited(address indexed sender, uint256 amount);

    // Track total winnings and losses for each user
    mapping(address => uint256) public totalWon;
    mapping(address => uint256) public totalLost;

    // Modifier to restrict access to owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Constructor to set the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }


    function depositFunds() external payable onlyOwner {
        emit FundsDeposited(msg.sender, msg.value);
    }


    function _getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), 
            block.prevrandao, 
            msg.sender
        )));
    }


    function playLotto(uint8[6] memory userNumbers) external payable {
        require(msg.value == gameFee, "Incorrect game fee");

        uint256 randomness = _getRandomNumber();

        uint8[6] memory winningNumbers;
        winningNumbers[0] = uint8(randomness % 49) + 1;
        winningNumbers[1] = uint8((randomness / 49) % 49) + 1;
        winningNumbers[2] = uint8((randomness / 49**2) % 49) + 1;
        winningNumbers[3] = uint8((randomness / 49**3) % 49) + 1;
        winningNumbers[4] = uint8((randomness / 49**4) % 49) + 1;
        winningNumbers[5] = uint8((randomness / 49**5) % 49) + 1;


        uint256 matches = _countMatches(userNumbers, winningNumbers);
        uint256 reward = 0;

        // Determine prize based on the number of matches
        if (matches == 6) {
            reward = msg.value * 10;  // Jackpot: 10x reward
        } else if (matches == 4) {
            reward = msg.value * 5;   // 4 matches: 5x reward
        } else if (matches == 2) {
            reward = msg.value * 2;   // 2 matches: 2x reward
        }

        if (reward > 0) {
            require(address(this).balance >= reward, "Insufficient contract balance");
            totalWon[msg.sender] += reward;
            payable(msg.sender).transfer(reward);
        } else {
            totalLost[msg.sender] += msg.value;
        }

        // Emit the game result
        emit GamePlayed(msg.sender, userNumbers, winningNumbers, reward);

    }

    function _countMatches(uint8[6] memory userNumbers, uint8[6] memory winningNumbers) 
        private 
        pure 
        returns (uint256 count) 
    {
        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 6; j++) {
                if (userNumbers[i] == winningNumbers[j]) {
                    count++;
                    break;  // Avoid duplicate counting
                }
            }
        }
    }

}