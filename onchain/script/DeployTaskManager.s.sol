// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TaskManager.sol";

contract DeployTaskManager is Script {
    function run() external {
        // Get the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the TaskManager contract
        TaskManager taskManager = new TaskManager();
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Log the deployed contract address
        console.log("TaskManager deployed at:", address(taskManager));
        console.log("Owner:", taskManager.owner());
        console.log("Keeper:", taskManager.getKeeper());
        console.log("Task count:", taskManager.getTaskCount());
    }
}
