// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title VerifyToken
 * @dev ERC20 token that mints 1 billion tokens to a specified address on deployment
 */
contract VerifyToken is ERC20 {
    // 1 billion tokens with 18 decimals
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18;
    
    // Address to receive the initial supply
    address public constant INITIAL_RECIPIENT = 0xCC4A81f07d9E925e90873349c903E3FE93099b0a;
    
    constructor() ERC20("VERIFY", "VERIFY") {
        _mint(INITIAL_RECIPIENT, INITIAL_SUPPLY);
    }
}
