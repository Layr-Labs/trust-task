// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaskManager is Ownable {
    // Task structure to store task information
    struct Task {
        uint256 id;
        address requester;
        address l1Address;
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

    // Events
    event TaskRequested(uint256 indexed taskId, address indexed requester, address indexed l1Address);
    event TaskCompleted(uint256 indexed taskId, address indexed keeper, bool result);
    event KeeperUpdated(address indexed oldKeeper, address indexed newKeeper);

    // Errors
    error TaskNotFound(uint256 taskId);
    error TaskAlreadyCompleted(uint256 taskId);
    error TaskNotCompleted(uint256 taskId);
    error InvalidKeeperAddress();
    error OnlyKeeperCanComplete();

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
     * @dev Request a new task
     * @param l1Address The L1 address associated with the task
     * @return taskId The ID of the created task
     */
    function requestTask(address l1Address) external returns (uint256 taskId) {
        taskId = _nextTaskId++;
        
        _tasks[taskId] = Task({
            id: taskId,
            requester: msg.sender,
            l1Address: l1Address,
            completed: false,
            result: false,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        _taskIds.push(taskId);
        
        emit TaskRequested(taskId, msg.sender, l1Address);
        
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
}
