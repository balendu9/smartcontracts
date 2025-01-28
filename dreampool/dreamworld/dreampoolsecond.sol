// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DreamPool {
    address public owner;
    uint256 public goalPoolIdCounter;
    uint256 public timerPoolIdCounter;
    uint256 counter;
    struct GoalBasedPool {
        uint256 poolId;
        uint256 entryFee;
        uint256 totalAmount;
        uint256 startTime;
        uint256 goalAmount;
        uint256 reward50Percent;
        uint256 reward15Percent;
        uint256 reward5Percent;
        uint256 rewardTreasury;
        address[] participants;
        bool isCompleted;
    }

    struct TimerBasedPool {
        uint256 poolId;
        uint256 entryFee;
        uint256 totalAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 reward50Percent;
        uint256 reward15Percent;
        uint256 reward5Percent;
        uint256 rewardTreasury;
        address[] participants;
        bool isCompleted;
    }

    mapping(uint256 => GoalBasedPool) public goalPools;
    mapping(uint256 => TimerBasedPool) public timerPools;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Authorized");
        _;
    }

    function _getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), 
            block.prevrandao, 
            msg.sender
        )));
    }

    function createGoalBasedPool(
        uint256 _entryFee,
        uint256 _goalAmount
    ) external onlyOwner {
        uint256 poolId = goalPoolIdCounter++;
        goalPools[poolId] = GoalBasedPool({
            poolId: counter,
            entryFee: _entryFee,
            totalAmount: 0,
            startTime: block.timestamp,
            goalAmount: _goalAmount,
            reward50Percent: 0,
            reward15Percent: 0,
            reward5Percent: 0,
            rewardTreasury: 0,
            participants: new address[](0),
            isCompleted: false
        });
        counter += 1;
    }

    function createTimerBasedPool(
        uint256 _entryFee,
        uint256 _duration
    ) external onlyOwner {
        uint256 poolId = timerPoolIdCounter++;
        timerPools[poolId] = TimerBasedPool({
            poolId: counter,
            entryFee: _entryFee,
            totalAmount: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            reward50Percent: 0,
            reward15Percent: 0,
            reward5Percent: 0,
            rewardTreasury: 0,
            participants: new address[](0),
            isCompleted: false
        });
        counter += 1;
    }

    function joinGoalBasedPool(uint256 _poolId) external payable {
        GoalBasedPool storage pool = goalPools[_poolId];
        require(!pool.isCompleted, "Pool already completed");
        require(msg.value == pool.entryFee, "Incorrect entry fee");

        pool.participants.push(msg.sender);
        pool.totalAmount += msg.value;
    }

    function joinTimerBasedPool(uint256 _poolId) external payable {
        TimerBasedPool storage pool = timerPools[_poolId];
        require(!pool.isCompleted, "Pool already completed");
        require(msg.value == pool.entryFee, "Incorrect entry fee");

        pool.participants.push(msg.sender);
        pool.totalAmount += msg.value;
    }

    function closeGoalBasedPool(uint256 _poolId) external onlyOwner {
        GoalBasedPool storage pool = goalPools[_poolId];
        require(!pool.isCompleted, "Pool already completed");
        require(pool.totalAmount >= pool.goalAmount, "Goal not reached");

        pool.isCompleted = true;
        calculateRewardGoalPool(_poolId);
    }

    function closeTimerBasedPool(uint256 _poolId) external onlyOwner {
        TimerBasedPool storage pool = timerPools[_poolId];
        require(!pool.isCompleted, "Pool already completed");
        require(block.timestamp >= pool.endTime, "Pool time not over");

        pool.isCompleted = true;
        calculateRewardTimerPool(_poolId);
    }

    function calculateRewardGoalPool(uint256 _poolId) private {
        uint256 randomness = _getRandomNumber();
        GoalBasedPool storage pool = goalPools[_poolId];
        uint256 randomFirstIndex = randomness % pool.participants.length;
        uint256 randomSecondIndex = (randomness / pool.participants.length) % pool.participants.length;
        uint256 randomThirdIndex = (randomness / pool.participants.length ** 2) % pool.participants.length;

        address winner50Percent = pool.participants[randomFirstIndex];
        address winner15Percent = pool.participants[randomSecondIndex];
        address winner5Percent = pool.participants[randomThirdIndex];

        pool.reward50Percent = (pool.totalAmount * 50) / 100;
        pool.reward15Percent = (pool.totalAmount * 15) / 100;
        pool.reward5Percent = (pool.totalAmount * 5) / 100;

        payable(winner50Percent).transfer(pool.reward50Percent);
        payable(winner15Percent).transfer(pool.reward15Percent);
        payable(winner5Percent).transfer(pool.reward5Percent);

        pool.rewardTreasury = (pool.totalAmount * 30) / 100;
        payable(owner).transfer(pool.rewardTreasury);
    }

    function calculateRewardTimerPool(uint256 _poolId) private {
        uint256 randomness = _getRandomNumber();
        TimerBasedPool storage pool = timerPools[_poolId];
        uint256 randomFirstIndex = randomness % pool.participants.length;
        uint256 randomSecondIndex = (randomness / pool.participants.length) % pool.participants.length;
        uint256 randomThirdIndex = (randomness / pool.participants.length ** 2) % pool.participants.length;

        address winner50Percent = pool.participants[randomFirstIndex];
        address winner15Percent = pool.participants[randomSecondIndex];
        address winner5Percent = pool.participants[randomThirdIndex];

        pool.reward50Percent = (pool.totalAmount * 50) / 100;
        pool.reward15Percent = (pool.totalAmount * 15) / 100;
        pool.reward5Percent = (pool.totalAmount * 5) / 100;

        payable(winner50Percent).transfer(pool.reward50Percent);
        payable(winner15Percent).transfer(pool.reward15Percent);
        payable(winner5Percent).transfer(pool.reward5Percent);

        pool.rewardTreasury = (pool.totalAmount * 30) / 100;
        payable(owner).transfer(pool.rewardTreasury);
    }

    function getGoalPoolById(uint256 _poolId) external view returns (GoalBasedPool memory) {
        return goalPools[_poolId];
    }

    function getTimerPoolById(uint256 _poolId) external view returns (TimerBasedPool memory) {
        return timerPools[_poolId];
    }

    function getAllGoalPools() external view returns (GoalBasedPool[] memory) {
        GoalBasedPool[] memory allPools = new GoalBasedPool[](goalPoolIdCounter);
        for (uint256 i = 0; i < goalPoolIdCounter; i++) {
            allPools[i] = goalPools[i];
        }
        return allPools;
    }

    function getAllTimerPools() external view returns (TimerBasedPool[] memory) {
        TimerBasedPool[] memory allPools = new TimerBasedPool[](timerPoolIdCounter);
        for (uint256 i = 0; i < timerPoolIdCounter; i++) {
            allPools[i] = timerPools[i];
        }
        return allPools;
    }

    function getAllPools() external view returns (uint256[] memory, uint256[] memory) {
        return (getAllGoalPoolIds(), getAllTimerPoolIds());
    }

    function getAllGoalPoolIds() internal view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](goalPoolIdCounter);
        for (uint256 i = 0; i < goalPoolIdCounter; i++) {
            ids[i] = i;
        }
        return ids;
    }

    function getAllTimerPoolIds() internal view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](timerPoolIdCounter);
        for (uint256 i = 0; i < timerPoolIdCounter; i++) {
            ids[i] = i;
        }
        return ids;
    }

    receive() external payable {}
}
