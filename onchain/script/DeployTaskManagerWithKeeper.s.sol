// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TaskManager.sol";

contract DeployTaskManagerWithKeeper is Script {
    function run() external {
        // Get the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        // Get keeper address from environment variable (optional)
        address keeperAddress = vm.envOr("KEEPER_ADDRESS", address(0));
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the TaskManager contract
        TaskManager taskManager = new TaskManager();
        
        // Set keeper if provided
        if (keeperAddress != address(0)) {
            taskManager.setKeeper(keeperAddress);
        }
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Log the deployed contract address and details
        console.log("=== TaskManager Deployment ===");
        console.log("Contract address:", address(taskManager));
        console.log("Owner:", taskManager.owner());
        console.log("Keeper:", taskManager.getKeeper());
        console.log("Task count:", taskManager.getTaskCount());
        
        if (keeperAddress != address(0)) {
            console.log("Keeper set to:", keeperAddress);
        } else {
            console.log("No keeper set - use setKeeper() to set one");
        }
    }
}
