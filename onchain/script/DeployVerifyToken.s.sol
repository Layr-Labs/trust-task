// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VerifyToken} from "../src/VerifyToken.sol";

contract DeployVerifyToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying VerifyToken...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        VerifyToken verifyToken = new VerifyToken();
        
        vm.stopBroadcast();
        
        console.log("VerifyToken deployed at:", address(verifyToken));
        console.log("Token name:", verifyToken.name());
        console.log("Token symbol:", verifyToken.symbol());
        console.log("Total supply:", verifyToken.totalSupply());
        console.log("Initial recipient:", verifyToken.INITIAL_RECIPIENT());
        console.log("Initial recipient balance:", verifyToken.balanceOf(verifyToken.INITIAL_RECIPIENT()));
    }
}
