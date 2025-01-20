// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface for the factory contract
interface ISavingsFactory {
    function getUserSavingsContracts(address user) external view returns (address[] memory);
}



contract SavingsGoal is Ownable {

    address public creator;
    string public goalType;
    uint256 public targetAmount;
    uint256 public currentAmount;
    uint256 public lockTime;
    uint256 public creationTime;

    // Contributors for joint savings
    address[] public contributors;

    // Mechanism: Flexbile, timebased or fixed locking

    enum LockingMechanism {Flexible, TimeBased, Fixed}
    LockingMechanism public lockingMechanism;

    // Event for tracking of contributions and withdrawal

    event Deposit(address indexed contributor, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed contributor, uint256 amount, uint256 timestamp);
    event GoalAchieved(uint256 timestamp);


    constructor() {
        // Default constructor for creating instances via factory only
    }


    /**
     * @notice Initializes a savings contract with the user's goal parameters.
     * @param _creator Address of the person creating the savings goal.
     * @param _goalType Type of the savings goal (e.g., Monthly, Birthday).
     * @param _targetAmount The target savings amount.
     * @param _lockTime The time until the savings are unlocked.
     * @param _lockingMechanism Type of locking mechanism.
     */


    function initialize(
        address _creator,
        string memory _goalType,
        uint256 _targetAmount,
        uint256 _lockTime,
        LockingMechanism _lockingMechanism
    ) external onlyOwner {
        creator = _creator;
        goalType = _goalType;
        targetAmount = _targetAmount;
        currentAmount = 0;
        lockTime = _lockTime;
        creationTime = block.timestamp;
        lockingMechanism = _lockingMechanism;
    }



    /**
     * @notice Allows contributors to deposit funds towards the savings goal.
     * @param amount The amount to deposit.
     */

    function deposit(uint256 amount) external {
        require(amount >0, "Amount must be greater than 0");
        require(currentAmount < targetAmount, "Goal already reached");

        // transfer the funds to this contract
        IERC20 token = IERC20(msg.sender);
        token.transferFrom(msg.sender, address(this), amount);

        currentAmount += amount;
        contributors.push(msg.sender);

        emit Deposit(msg.sender, amount, block.timestamp);

        if(currentAmount >= targetAmount) {
            emit GoalAchieved(block.timestamp);
        }
    }


    /**
     * @notice Allows the creator or contributors to withdraw funds from the savings goal.
     * @param amount The amount to withdraw.
     */

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(currentAmount >= amount, "Insufficient funds");
        require(block.timestamp >= lockTime || lockingMechanism == LockingMechanism.Flexible, "Funds are locked");

        // Only the creator or contributors can withdraw
        require(msg.sender == creator || isContributor(msg.sender), "Not authorized");

        // Transfer the funds to the user
        IERC20 token = IERC20(msg.sender); // Assuming the sender has the token
        token.transfer(msg.sender, amount);

        currentAmount -= amount;

        emit Withdrawal(msg.sender, amount, block.timestamp);
    }

    /**
     * @notice Check if an address is a contributor
     * @param addr The address to check
     * @return bool True if the address is a contributor
     */
    function isContributor(address addr) internal view returns (bool) {
        for (uint i = 0; i < contributors.length; i++) {
            if (contributors[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get the balance of the savings goal.
     * @return uint256 The current savings balance.
     */
    function getBalance() external view returns (uint256) {
        return currentAmount;
    }

    /**
     * @notice Get the number of contributors.
     * @return uint256 The number of contributors.
     */
    function getContributorsCount() external view returns (uint256) {
        return contributors.length;
    }

    /**
     * @notice Allows the creator to set the lock time.
     * @param _lockTime New lock time (in seconds).
     */
    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }

    /**
     * @notice Allows the creator to change the locking mechanism.
     * @param _lockingMechanism The new locking mechanism.
     */
    function setLockingMechanism(LockingMechanism _lockingMechanism) external onlyOwner {
        lockingMechanism = _lockingMechanism;
    }
}