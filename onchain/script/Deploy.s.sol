// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TaskManager.sol";

contract Deploy is Script {
    function run() external {
        // Get the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the TaskManager contract
        TaskManager taskManager = new TaskManager();
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Log deployment information
        console.log("=== TaskManager Deployed ===");
        console.log("Network:", vm.toString(block.chainid));
        console.log("Contract address:", address(taskManager));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Owner:", taskManager.owner());
        console.log("Keeper:", taskManager.getKeeper());
        console.log("Gas used:", gasleft());
    }
}
