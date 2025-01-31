// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DreamPool {
    address public owner;
    uint256 public poolIdCounter;

    mapping(address => bool) public whitelisted;
    address[] public whitelistedUsers;

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

        if (!whitelisted[msg.sender]) {
            whitelisted[msg.sender] = true;
        }
        whitelistedUsers.push(msg.sender);
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

    // function getTimerPoolById(uint256 _poolId) external view returns (Pool memory) {
    //     require(_poolId <= poolIdCounter, "Invalid Pool ID");
    //     Pool storage pool = pools[_poolId];
    //     require(!pool.isGoalBased, "Not a Timer-based Pool");
    //     return pool;
    // }

    // function getGoalPoolById(uint256 _poolId) external view returns (Pool memory) {
    //     require(_poolId <= poolIdCounter, "Invalid Pool ID");
    //     Pool storage pool = pools[_poolId];
    //     require(pool.isGoalBased, "Not a Goal-based Pool");
    //     return pool;
    // }

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


    function getPoolById(uint256 _poolId) external view returns (
        uint256 poolId,
        uint256 entryFee,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime,
        uint256 goalAmount,
        uint256 reward50Percent,
        uint256 reward15Percent,
        uint256 reward5Percent,
        uint256 rewardTreasury,
        bool isGoalBased,
        bool isCompleted
    ) {
        Pool storage pool = pools[_poolId];
        return (
            pool.poolId,
            pool.entryFee,
            pool.totalAmount,
            pool.startTime,
            pool.endTime,
            pool.goalAmount,
            pool.reward50Percent,
            pool.reward15Percent,
            pool.reward5Percent,
            pool.rewardTreasury,
            pool.isGoalBased,
            pool.isCompleted
        );
    }






// game for users





event gamePlayed(address indexed player, uint256 amountPaid, uint256 reward);


function playGame() external payable {
    require(msg.value > 0, "Amount must be greater than zero");
    uint256 amountPaid = msg.value;
    uint256 randomValue = _getRandomNumber() % 100;

    uint256 reward;
    if (randomValue > 70 && randomValue < 80) {
            // 80% chance for a smaller reward
            reward = amountPaid * (25 + (randomValue % 75)) / 100; 
        } else {
            // 20% chance for a larger reward
            reward = amountPaid * (100 + (randomValue % 100)) / 100;
        }


    payable(msg.sender).transfer(reward);
    emit gamePlayed(msg.sender, amountPaid, reward);

}




    // airdrop


    mapping(address => bool) public hasClaimed;


    uint256 public airdropAmount;
    uint256 public totalAmount;
    uint256 public airdropStartTime;
    uint8 counter = 0;
    uint8 totalClaimable=0;
    event AirdropClaimed(address indexed claimant, uint256 amount);
    function claimAirdrop() external {
        require(whitelisted[msg.sender], "You are not qualified, try taking part in any pool");
        require(!hasClaimed[msg.sender], "You have alredy calimed the reward");
        require(address(this).balance >= airdropAmount, "Insufficient airdrop funds");
        require(block.timestamp >= airdropStartTime, "Airdrop has not started yet");
        require(block.timestamp <= airdropStartTime + 3600, "Damm you missed it this time");
        require(counter <= totalClaimable, "Early bird catches the bug!! But you are late!!");  
        hasClaimed[msg.sender] = true;
        whitelisted[msg.sender]= false;

        payable(msg.sender).transfer(airdropAmount);

        emit AirdropClaimed(msg.sender, airdropAmount);

    } 



    function setAirdropDetails(uint256 _totalAmount, uint256 _newAmount, uint256 _newStartTime, uint8 _totalClaimable) external onlyOwner {
        totalAmount= _totalAmount;
        airdropAmount = _newAmount;
        airdropStartTime= _newStartTime;
        totalClaimable = _totalAmount;

    }




    receive() external payable{}



}
