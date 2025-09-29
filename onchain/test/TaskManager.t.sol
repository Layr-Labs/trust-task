// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/TaskManager.sol";

contract TaskManagerTest is Test {
    TaskManager public taskManager;
    address public owner;
    address public keeper;
    address public user;

    function setUp() public {
        owner = address(this);
        keeper = makeAddr("keeper");
        user = makeAddr("user");
        
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
}
