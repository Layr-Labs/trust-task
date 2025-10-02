# VERIFY Token

## Overview

VERIFY is an ERC20 token that mints 1 billion tokens to a specified address upon deployment.

## Contract Details

- **Name**: VERIFY
- **Symbol**: VERIFY
- **Decimals**: 18
- **Total Supply**: 1,000,000,000 VERIFY (1 billion tokens)
- **Initial Recipient**: `0x7411a46800a1094d3fFF237b39f0624Fc1A434C3`

## Deployment

### Using the deployment script:

```bash
# Deploy to Sepolia testnet
./deploy-verify.sh sepolia

# Deploy to localhost
./deploy-verify.sh localhost

# Deploy to mainnet
./deploy-verify.sh mainnet
```

### Using Foundry directly:

```bash
# Deploy to Sepolia
forge script script/DeployVerifyToken.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy to localhost
forge script script/DeployVerifyToken.s.sol --rpc-url http://localhost:8545 --broadcast
```

## Testing

Run the test suite:

```bash
forge test --match-contract VerifyTokenTest -vv
```

## Features

- Standard ERC20 functionality (transfer, approve, transferFrom)
- 1 billion tokens minted to specified address on deployment
- 18 decimal places for precision
- OpenZeppelin ERC20 implementation for security

## Security

The contract uses OpenZeppelin's battle-tested ERC20 implementation, ensuring:
- Safe arithmetic operations
- Proper access controls
- Standard ERC20 compliance
- No reentrancy vulnerabilities
