// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TaskManager is Ownable {
    // Task types
    enum TaskType {
        BALANCE_CHECK,
        DISTRIBUTE_VERIFY_TOKEN
    }

    // Task structure to store task information
    struct Task {
        uint256 id;
        address requester;
        address l1Address;
        TaskType taskType;
        bool completed;
        bool result;
        uint256 createdAt;
        uint256 completedAt;
    }

    // State variables
    uint256 private _nextTaskId;
    address private _keeper;
    mapping(uint256 => Task) private _tasks;
    uint256[] private _taskIds;
    
    // VERIFY token configuration
    address public constant VERIFY_TOKEN = 0xBB8d2C98B6E3595f2a146dBCFFDe3AE52728981e;
    uint256 public constant VERIFY_DISTRIBUTION_AMOUNT = 10 * 10**18; // 10 VERIFY tokens

    // Events
    event TaskRequested(uint256 indexed taskId, address indexed requester, address indexed l1Address, TaskType taskType);
    event TaskCompleted(uint256 indexed taskId, address indexed keeper, bool result);
    event KeeperUpdated(address indexed oldKeeper, address indexed newKeeper);
    event VerifyTokenDistributed(uint256 indexed taskId, address indexed recipient, uint256 amount);

    // Errors
    error TaskNotFound(uint256 taskId);
    error TaskAlreadyCompleted(uint256 taskId);
    error TaskNotCompleted(uint256 taskId);
    error InvalidKeeperAddress();
    error OnlyKeeperCanComplete();
    error InsufficientVerifyTokenBalance();
    error VerifyTokenTransferFailed();

    constructor() Ownable(msg.sender) {
        _nextTaskId = 1;
    }

    // Modifier to ensure only the keeper can complete tasks
    modifier keptBy(address keeper) {
        if (msg.sender != keeper) {
            revert OnlyKeeperCanComplete();
        }
        _;
    }

    // Modifier to ensure task exists
    modifier taskExists(uint256 taskId) {
        if (taskId == 0 || taskId >= _nextTaskId) {
            revert TaskNotFound(taskId);
        }
        _;
    }

    // Modifier to ensure task is not already completed
    modifier notCompleted(uint256 taskId) {
        if (_tasks[taskId].completed) {
            revert TaskAlreadyCompleted(taskId);
        }
        _;
    }

    /**
     * @dev Request a new balance check task
     * @param l1Address The L1 address associated with the task
     * @return taskId The ID of the created task
     */
    function requestTask(address l1Address) external returns (uint256 taskId) {
        taskId = _nextTaskId++;
        
        _tasks[taskId] = Task({
            id: taskId,
            requester: msg.sender,
            l1Address: l1Address,
            taskType: TaskType.BALANCE_CHECK,
            completed: false,
            result: false,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        _taskIds.push(taskId);
        
        emit TaskRequested(taskId, msg.sender, l1Address, TaskType.BALANCE_CHECK);
        
        return taskId;
    }

    /**
     * @dev Request a new VERIFY token distribution task
     * @param l1Address The L1 address to receive VERIFY tokens
     * @return taskId The ID of the created task
     */
    function requestDistributeVerifyToken(address l1Address) external returns (uint256 taskId) {
        taskId = _nextTaskId++;
        
        _tasks[taskId] = Task({
            id: taskId,
            requester: msg.sender,
            l1Address: l1Address,
            taskType: TaskType.DISTRIBUTE_VERIFY_TOKEN,
            completed: false,
            result: false,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        _taskIds.push(taskId);
        
        emit TaskRequested(taskId, msg.sender, l1Address, TaskType.DISTRIBUTE_VERIFY_TOKEN);
        
        return taskId;
    }

    /**
     * @dev Complete a task (only keeper can call this)
     * @param taskId The ID of the task to complete
     * @param result The result of the task completion
     */
    function completeTask(uint256 taskId, bool result) 
        external 
        keptBy(_keeper) 
        taskExists(taskId) 
        notCompleted(taskId) 
    {
        _tasks[taskId].completed = true;
        _tasks[taskId].result = result;
        _tasks[taskId].completedAt = block.timestamp;
        
        // If this is a VERIFY token distribution task and result is true, distribute tokens
        if (_tasks[taskId].taskType == TaskType.DISTRIBUTE_VERIFY_TOKEN && result) {
            _distributeVerifyTokens(taskId, _tasks[taskId].l1Address);
        }
        
        emit TaskCompleted(taskId, msg.sender, result);
    }

    /**
     * @dev Set the keeper address (only owner can call this)
     * @param newKeeper The new keeper address
     */
    function setKeeper(address newKeeper) external onlyOwner {
        if (newKeeper == address(0)) {
            revert InvalidKeeperAddress();
        }
        
        address oldKeeper = _keeper;
        _keeper = newKeeper;
        
        emit KeeperUpdated(oldKeeper, newKeeper);
    }

    /**
     * @dev Get task information
     * @param taskId The ID of the task
     * @return task The task information
     */
    function getTask(uint256 taskId) external view taskExists(taskId) returns (Task memory) {
        return _tasks[taskId];
    }

    /**
     * @dev Get the result of a completed task
     * @param taskId The ID of the task
     * @return result The result of the task
     */
    function getResult(uint256 taskId) external view taskExists(taskId) returns (bool result) {
        if (!_tasks[taskId].completed) {
            revert TaskNotCompleted(taskId);
        }
        return _tasks[taskId].result;
    }

    /**
     * @dev Get all task IDs
     * @return Array of all task IDs
     */
    function getAllTaskIds() external view returns (uint256[] memory) {
        return _taskIds;
    }

    /**
     * @dev Get the current keeper address
     * @return The keeper address
     */
    function getKeeper() external view returns (address) {
        return _keeper;
    }

    /**
     * @dev Get the total number of tasks
     * @return The total number of tasks
     */
    function getTaskCount() external view returns (uint256) {
        return _taskIds.length;
    }

    /**
     * @dev Internal function to distribute VERIFY tokens
     * @param taskId The ID of the task
     * @param recipient The address to receive the tokens
     */
    function _distributeVerifyTokens(uint256 taskId, address recipient) internal {
        IERC20 verifyToken = IERC20(VERIFY_TOKEN);
        
        // Check if contract has enough VERIFY tokens
        uint256 contractBalance = verifyToken.balanceOf(address(this));
        if (contractBalance < VERIFY_DISTRIBUTION_AMOUNT) {
            revert InsufficientVerifyTokenBalance();
        }
        
        // Transfer VERIFY tokens to recipient
        bool success = verifyToken.transfer(recipient, VERIFY_DISTRIBUTION_AMOUNT);
        if (!success) {
            revert VerifyTokenTransferFailed();
        }
        
        emit VerifyTokenDistributed(taskId, recipient, VERIFY_DISTRIBUTION_AMOUNT);
    }

    /**
     * @dev Get the VERIFY token balance of this contract
     * @return The VERIFY token balance
     */
    function getVerifyTokenBalance() external view returns (uint256) {
        return IERC20(VERIFY_TOKEN).balanceOf(address(this));
    }

    /**
     * @dev Get the VERIFY token address
     * @return The VERIFY token address
     */
    function getVerifyTokenAddress() external pure returns (address) {
        return VERIFY_TOKEN;
    }

    /**
     * @dev Get the VERIFY token distribution amount
     * @return The distribution amount
     */
    function getVerifyDistributionAmount() external pure returns (uint256) {
        return VERIFY_DISTRIBUTION_AMOUNT;
    }
}
