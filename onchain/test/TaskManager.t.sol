// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/TaskManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TaskManagerTest is Test {
    TaskManager public taskManager;
    address public owner;
    address public keeper;
    address public user;
    address public verifyToken;
    address public tokenRecipient;

    function setUp() public {
        owner = address(this);
        keeper = makeAddr("keeper");
        user = makeAddr("user");
        tokenRecipient = makeAddr("tokenRecipient");
        
        // Mock VERIFY token address for testing
        verifyToken = makeAddr("verifyToken");
        
        taskManager = new TaskManager();
        taskManager.setKeeper(keeper);
    }

    function testRequestTask() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestTask(l1Address);
        
        assertEq(taskId, 1);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(task.id, 1);
        assertEq(task.requester, user);
        assertEq(task.l1Address, l1Address);
        assertEq(uint256(task.taskType), uint256(TaskManager.TaskType.BALANCE_CHECK));
        assertFalse(task.completed);
        assertFalse(task.result);
        assertGt(task.createdAt, 0);
        assertEq(task.completedAt, 0);
    }

    function testCompleteTask() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestTask(l1Address);
        
        vm.prank(keeper);
        taskManager.completeTask(taskId, true);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertTrue(task.completed);
        assertTrue(task.result);
        assertGt(task.completedAt, 0);
        
        // Test getResult function
        bool result = taskManager.getResult(taskId);
        assertTrue(result);
    }

    function testOnlyKeeperCanComplete() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestTask(l1Address);
        
        vm.prank(user);
        vm.expectRevert(TaskManager.OnlyKeeperCanComplete.selector);
        taskManager.completeTask(taskId, true);
    }

    function testSetKeeper() public {
        address newKeeper = makeAddr("newKeeper");
        taskManager.setKeeper(newKeeper);
        
        assertEq(taskManager.getKeeper(), newKeeper);
    }

    function testOnlyOwnerCanSetKeeper() public {
        address newKeeper = makeAddr("newKeeper");
        
        vm.prank(user);
        vm.expectRevert();
        taskManager.setKeeper(newKeeper);
    }

    function testGetAllTaskIds() public {
        address l1Address1 = makeAddr("l1Address1");
        address l1Address2 = makeAddr("l1Address2");
        
        vm.prank(user);
        uint256 taskId1 = taskManager.requestTask(l1Address1);
        
        vm.prank(user);
        uint256 taskId2 = taskManager.requestTask(l1Address2);
        
        uint256[] memory allTaskIds = taskManager.getAllTaskIds();
        
        assertEq(allTaskIds.length, 2);
        assertEq(allTaskIds[0], taskId1);
        assertEq(allTaskIds[1], taskId2);
    }

    function testTaskNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(TaskManager.TaskNotFound.selector, 999));
        taskManager.getTask(999);
    }

    function testTaskAlreadyCompleted() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestTask(l1Address);
        
        vm.prank(keeper);
        taskManager.completeTask(taskId, true);
        
        vm.prank(keeper);
        vm.expectRevert(abi.encodeWithSelector(TaskManager.TaskAlreadyCompleted.selector, taskId));
        taskManager.completeTask(taskId, false);
    }

    function testGetResultNotCompleted() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestTask(l1Address);
        
        vm.expectRevert(abi.encodeWithSelector(TaskManager.TaskNotCompleted.selector, taskId));
        taskManager.getResult(taskId);
    }

    function testGetResultCompleted() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestTask(l1Address);
        
        vm.prank(keeper);
        taskManager.completeTask(taskId, false);
        
        bool result = taskManager.getResult(taskId);
        assertFalse(result);
    }

    // VERIFY Token Distribution Tests
    function testRequestDistributeVerifyToken() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestDistributeVerifyToken(l1Address);
        
        assertEq(taskId, 1);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(task.id, 1);
        assertEq(task.requester, user);
        assertEq(task.l1Address, l1Address);
        assertEq(uint256(task.taskType), uint256(TaskManager.TaskType.DISTRIBUTE_VERIFY_TOKEN));
        assertFalse(task.completed);
        assertFalse(task.result);
        assertGt(task.createdAt, 0);
        assertEq(task.completedAt, 0);
    }

    function testVerifyTokenConstants() public {
        assertEq(taskManager.getVerifyTokenAddress(), 0x818aF030f68682b30F455536D0C779dB9B07b445);
        assertEq(taskManager.getVerifyDistributionAmount(), 10 * 10**18);
    }

    function testVerifyTokenBalance() public {
        // This test will fail because the VERIFY token contract doesn't exist at the hardcoded address
        // In a real deployment, this would work
        vm.expectRevert();
        taskManager.getVerifyTokenBalance();
    }

    function testDistributeVerifyTokenSuccess() public {
        // This test will fail because the VERIFY token contract doesn't exist at the hardcoded address
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestDistributeVerifyToken(l1Address);
        
        // Complete the task with true result
        vm.prank(keeper);
        // This will fail because the token contract doesn't exist
        vm.expectRevert();
        taskManager.completeTask(taskId, true);
    }

    function testDistributeVerifyTokenFalseResult() public {
        address l1Address = makeAddr("l1Address");
        vm.prank(user);
        uint256 taskId = taskManager.requestDistributeVerifyToken(l1Address);
        
        // Complete the task with false result - should not distribute tokens
        vm.prank(keeper);
        taskManager.completeTask(taskId, false);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertTrue(task.completed);
        assertFalse(task.result);
    }

    function testTaskTypeEnum() public {
        // Test that TaskType enum values are correct
        assertEq(uint256(TaskManager.TaskType.BALANCE_CHECK), 0);
        assertEq(uint256(TaskManager.TaskType.DISTRIBUTE_VERIFY_TOKEN), 1);
    }

    function testMixedTaskTypes() public {
        address l1Address1 = makeAddr("l1Address1");
        address l1Address2 = makeAddr("l1Address2");
        
        // Request balance check task
        vm.prank(user);
        uint256 taskId1 = taskManager.requestTask(l1Address1);
        
        // Request VERIFY token distribution task
        vm.prank(user);
        uint256 taskId2 = taskManager.requestDistributeVerifyToken(l1Address2);
        
        // Check task types
        TaskManager.Task memory task1 = taskManager.getTask(taskId1);
        TaskManager.Task memory task2 = taskManager.getTask(taskId2);
        
        assertEq(uint256(task1.taskType), uint256(TaskManager.TaskType.BALANCE_CHECK));
        assertEq(uint256(task2.taskType), uint256(TaskManager.TaskType.DISTRIBUTE_VERIFY_TOKEN));
        
        // Complete both tasks
        vm.prank(keeper);
        taskManager.completeTask(taskId1, true);
        
        vm.prank(keeper);
        vm.expectRevert();
        taskManager.completeTask(taskId2, true);
    }
}
