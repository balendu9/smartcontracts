// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import "witnet-solidity-bridge/contracts/interfaces/IWitnetRandomness.sol";


contract SlotMachine {
   string[6] public symbols = ["1", "2", "3", "4", "5", "6"];
   uint256 public minimumBet = 0.01 ether;
   address public owner;


   IWitnetRandomness public witnetRandomness;


   event SpinResult(address indexed player, string[3] result, bool isWinner, uint256 payout);


   modifier onlyOwner() {
       require(msg.sender == owner, "Not authorized");
       _;
   }


constructor(address witnetRandomnessAddress) {
       owner = msg.sender;
       witnetRandomness = IWitnetRandomness(witnetRandomnessAddress);
   }


   function spin() public payable {
       require(msg.value >= minimumBet, "Bet amount too low");


       uint256 randomness = witnetRandomness.randomize();


       uint256 reel1 = randomness % symbols.length;
       uint256 reel2 = (randomness / symbols.length) % symbols.length;
       uint256 reel3 = (randomness / symbols.length**2) % symbols.length;


       string[3] memory result = [symbols[reel1], symbols[reel2], symbols[reel3]];
       bool isWinner = (reel1 == reel2 && reel2 == reel3);
       uint256 payout = isWinner ? msg.value * 10 : 0;


       if (isWinner) {
        require(address(this).balance >= payout, "Insufficient contract balance");
           payable(msg.sender).transfer(payout);
       }


       emit SpinResult(msg.sender, result, isWinner, payout);
   }


   function depositFunds() external payable onlyOwner {}


   function withdrawFunds(uint256 amount) external onlyOwner {
       require(address(this).balance >= amount, "Insufficient funds");
       payable(owner).transfer(amount);
   }


   receive() external payable {}
}
