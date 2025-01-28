// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DreamPool {
    address public owner;
    uint256 public poolIdCounter;

    struct Pool {
        uint256 poolId;
        uint256 entryFee;
        uint256 totalAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 goalAmount;
        uint256 reward50Percent;
        uint256 reward15Percent;
        uint256 reward5Percent;
        uint256 rewardTreasury;
        address[] participants;
        bool isGoalBased;
        bool isCompleted;
    }

    mapping (uint256 => Pool) public pools;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Authorized");
        _;
    }



    // generate random number
    function _getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), 
            block.prevrandao, 
            msg.sender
        )));
    }

    
    function createPool(
        uint256 _entryFee,
        uint256 _goalAmount,
        uint256 _duration,
        bool _isGoalBased
    ) external onlyOwner {
        uint256 poolId = poolIdCounter++;
        uint256 endTime = _isGoalBased ? 0 : block.timestamp + _duration;
        pools[poolId] = Pool({
            poolId: poolId,
            entryFee: _entryFee,
            totalAmount: 0,
            startTime: block.timestamp,
            endTime: endTime,
            goalAmount: _goalAmount,
            reward50Percent: 0,
            reward15Percent: 0,
            reward5Percent: 0,
            rewardTreasury: 0,
            participants: new address[](0),
            isGoalBased: _isGoalBased,
            isCompleted: false
        });

    }



    function joinPool(uint256 _poolId) external payable {
        Pool storage pool = pools[_poolId];

        require(!pool.isCompleted, "Pool already completed");
        require(msg.value == pool.entryFee, "Incorrect entry fee");

        pool.participants.push(msg.sender);
        pool.totalAmount += msg.value;
    }

    function closePool(uint256 _poolId) external onlyOwner {
        Pool storage pool = pools[_poolId];

        require(!pool.isCompleted, "Pool already completed");

        if(pool.isGoalBased) {
            require(pool.totalAmount >= pool.goalAmount, "Goal not reached");
        } else {
            require(block.timestamp >= pool.endTime, "Pool time not over");
        }

        pool.isCompleted = true;
        calculateReward(_poolId);
    }


    function calculateReward(uint256 _poolId) private {
        uint256 randomness = _getRandomNumber();
        Pool storage pool = pools[_poolId];
        uint256 randomFirstIndex = randomness % pool.participants.length;
        uint256 randomSecondIndex = (randomness / pool.participants.length ) % pool.participants.length;
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



    function getTimerPoolById(uint256 _poolId) external view returns (Pool memory) {
        Pool storage pool = pools[_poolId];
        require(!pool.isGoalBased, "Not a Timer-based Pool");
        return pool;
    }

    function getGoalPoolById(uint256 _poolId) external view returns (Pool memory) {
        Pool storage pool = pools[_poolId];
        require(pool.isGoalBased, "Not a Goal-based Pool");
        return pool;
    }

    function getAllTimerPools() external view returns (Pool[] memory) {
        uint256 timerPoolsCount = 0;
        for (uint256 i = 0; i < poolIdCounter; i++) {
            if (!pools[i].isGoalBased) {
                timerPoolsCount++;
            }
        }

        Pool[] memory timerPools = new Pool[](timerPoolsCount);
        uint256 index = 0;
        for (uint256 i = 0; i < poolIdCounter; i++) {
            if (!pools[i].isGoalBased) {
                timerPools[index] = pools[i];
                index++;
            }
        }

        return timerPools;
    }

    function getAllGoalPools() external view returns (Pool[] memory) {
        uint256 goalPoolsCount = 0;
        for (uint256 i = 0; i < poolIdCounter; i++) {
            if (pools[i].isGoalBased) {
                goalPoolsCount++;
            }
        }

        Pool[] memory goalPools = new Pool[](goalPoolsCount);
        uint256 index = 0;
        for (uint256 i = 0; i < poolIdCounter; i++) {
            if (pools[i].isGoalBased) {
                goalPools[index] = pools[i];
                index++;
            }
        }

        return goalPools;
    }

    function getAllPools() external view returns (Pool[] memory) {
        Pool[] memory allPools = new Pool[](poolIdCounter);
        for (uint256 i = 0; i < poolIdCounter; i++) {
            allPools[i] = pools[i];
        }
        return allPools;
    }
    receive() external payable{}



}