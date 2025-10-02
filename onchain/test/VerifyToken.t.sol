// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {VerifyToken} from "../src/VerifyToken.sol";

contract VerifyTokenTest is Test {
    VerifyToken public verifyToken;
    address public constant INITIAL_RECIPIENT = 0x36803870c8000708264B2dE6bCe67c8bF1da5447;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18;
    
    function setUp() public {
        verifyToken = new VerifyToken();
    }
    
    function testTokenName() public {
        assertEq(verifyToken.name(), "VERIFY");
    }
    
    function testTokenSymbol() public {
        assertEq(verifyToken.symbol(), "VERIFY");
    }
    
    function testDecimals() public {
        assertEq(verifyToken.decimals(), 18);
    }
    
    function testTotalSupply() public {
        assertEq(verifyToken.totalSupply(), INITIAL_SUPPLY);
    }
    
    function testInitialRecipient() public {
        assertEq(verifyToken.INITIAL_RECIPIENT(), INITIAL_RECIPIENT);
    }
    
    function testInitialSupplyMinted() public {
        assertEq(verifyToken.balanceOf(INITIAL_RECIPIENT), INITIAL_SUPPLY);
    }
    
    function testOnlyInitialRecipientHasTokens() public {
        address otherAddress = makeAddr("other");
        assertEq(verifyToken.balanceOf(otherAddress), 0);
    }
    
    function testTransfer() public {
        address recipient = makeAddr("recipient");
        uint256 transferAmount = 1000 * 10**18;
        
        vm.prank(INITIAL_RECIPIENT);
        bool success = verifyToken.transfer(recipient, transferAmount);
        
        assertTrue(success);
        assertEq(verifyToken.balanceOf(recipient), transferAmount);
        assertEq(verifyToken.balanceOf(INITIAL_RECIPIENT), INITIAL_SUPPLY - transferAmount);
    }
    
    function testTransferFrom() public {
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        uint256 transferAmount = 1000 * 10**18;
        
        // Approve spender
        vm.prank(INITIAL_RECIPIENT);
        verifyToken.approve(spender, transferAmount);
        
        // Transfer from
        vm.prank(spender);
        bool success = verifyToken.transferFrom(INITIAL_RECIPIENT, recipient, transferAmount);
        
        assertTrue(success);
        assertEq(verifyToken.balanceOf(recipient), transferAmount);
        assertEq(verifyToken.balanceOf(INITIAL_RECIPIENT), INITIAL_SUPPLY - transferAmount);
        assertEq(verifyToken.allowance(INITIAL_RECIPIENT, spender), 0);
    }
    
    function testInsufficientBalance() public {
        address recipient = makeAddr("recipient");
        uint256 transferAmount = INITIAL_SUPPLY + 1;
        
        vm.prank(INITIAL_RECIPIENT);
        vm.expectRevert();
        verifyToken.transfer(recipient, transferAmount);
    }
    
    function testInsufficientAllowance() public {
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        uint256 transferAmount = 1000 * 10**18;
        
        // Try to transfer without approval
        vm.prank(spender);
        vm.expectRevert();
        verifyToken.transferFrom(INITIAL_RECIPIENT, recipient, transferAmount);
    }
}
