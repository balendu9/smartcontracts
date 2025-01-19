// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's Ownable for access control
import "./@openzeppelin/contracts/access/Ownable.sol";

// Interface for the savings contracts
interface ISavingsContract {
    function initialize(
        address _creator,
        string memory _goalType,
        uint256 _targetAmount,
        uint256 _lockTime
    ) external;
}


contract SavingsFactory is Ownable {
    // to track all the deployed contract
    address[] public allSavingsContracts;

    // mapping to associate users with their savings contracts
    mapping(address => address[]) public userSavingsContracts;

    // Event to log the creation of new contract
    event SavingsContractCreated(
        address indexed user,
        address indexed savingsContract,
        string goalType,
        uint256 targetAmount,
        uint256 lockTime,
        uint256 timestamp
    );

    /**
     * @notice Deploys a new savings contract.
     * @param savingsContractTemplate Address of the savings contract template to use.
     * @param goalType Type of goal for the savings (e.g., Monthly, Birthday).
     * @param targetAmount Target amount for the savings goal.
     * @param lockTime Time (in seconds) until the funds are unlocked.
     */
    
    function createSavingsContract(
        address savingsContractTemplate,
        string memory goalType,
        uint256 targetAmount,
        uint256 lockTime
    ) external {
        require(targetAmount > 0, "Target amount must be greater than zero");
        require(lockTime > block.timestamp, "Lock time must be in the future");

        address newSavingsContract = deploySavingsContract(savingsContractTemplate);

        // initialize new contract
        ISavingsContract(newSavingsContract).initialize(
            msg.sender,
            goalType,
            targetAmount,
            lockTime
        );

        // Track all new contract

        allSavingsContracts.push(newSavingsContract);
        userSavingsContracts[msg.sender].push(newSavingsContract);

        emit SavingsContractCreated(
            msg.sender,
            newSavingsContract,
            goalType,
            targetAmount,
            lockTime,
            block.timestamp
        );

    }


     /**
     * @notice Returns all savings contracts created by a specific user.
     * @param user Address of the user.
     * @return Array of savings contract addresses.
     */
    function getUserSavingsContracts(address user) external view returns (address[] memory) {
        return userSavingsContracts[user];
    }



    /**
     * @notice Internal function to deploy a new savings contract.
     * @param savingsContractTemplate Address of the contract template to clone.
     * @return Address of the newly deployed contract.
     */
    function deploySavingsContract(address savingsContractTemplate) internal returns (address) {
        require(savingsContractTemplate != address(0), "Invalid contract template address");

        // Create a new contract using the create2 opcode
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        address newContract;
        assembly {
            newContract := create2(0, add(savingsContractTemplate, 0x20), mload(savingsContractTemplate), salt)
            if iszero(extcodesize(newContract)) {
                revert(0, 0)
            }
        }
        return newContract;
    }


}