# TaskManager Deployment Guide

This guide explains how to deploy the TaskManager contract using the provided deployment scripts.

## Prerequisites

1. Set up your environment variables:
   ```bash
   export DEPLOYER_PRIVATE_KEY="your_private_key_here"
   ```

2. Optional: Set keeper address during deployment:
   ```bash
   export KEEPER_ADDRESS="0x1234567890123456789012345678901234567890"
   ```

3. Optional: Set API keys for contract verification:
   ```bash
   export ETHERSCAN_API_KEY="your_etherscan_api_key"
   export POLYGONSCAN_API_KEY="your_polygonscan_api_key"
   export ARBISCAN_API_KEY="your_arbiscan_api_key"
   export BASESCAN_API_KEY="your_basescan_api_key"
   export INFURA_API_KEY="your_infura_api_key"
   ```

## RPC Provider Options

### Free Public RPCs (No API Key Required)
- **Ethereum Mainnet**: `https://eth.llamarpc.com`
- **Ethereum Sepolia**: 
  - `https://ethereum-sepolia-rpc.publicnode.com` (recommended)
  - `https://sepolia.gateway.tenderly.co`
  - `https://sepolia.drpc.org`
- **Polygon**: `https://polygon.llamarpc.com`
- **Base Sepolia**: `https://sepolia.base.org`
- **Base Mainnet**: `https://mainnet.base.org`

### Premium RPC Providers (API Key Required)
- **Infura**: `https://sepolia.infura.io/v3/<API_KEY>`
- **Alchemy**: `https://eth-sepolia.g.alchemy.com/v2/<API_KEY>`
- **QuickNode**: `https://your-endpoint.quiknode.pro/<API_KEY>/`

## Deployment Scripts

### 1. Basic Deployment (`Deploy.s.sol`)
Deploys the TaskManager contract with basic logging.

```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast --verify
```

### 2. TaskManager-Specific Deployment (`DeployTaskManager.s.sol`)
Deploys the TaskManager contract with detailed contract information.

```bash
forge script script/DeployTaskManager.s.sol --rpc-url <RPC_URL> --broadcast --verify
```

### 3. Deployment with Keeper Setup (`DeployTaskManagerWithKeeper.s.sol`)
Deploys the TaskManager contract and optionally sets a keeper address.

```bash
forge script script/DeployTaskManagerWithKeeper.s.sol --rpc-url <RPC_URL> --broadcast --verify
```

## Using the Shell Script

The `deploy.sh` script provides an easy way to deploy to different networks:

```bash
# Deploy to localhost
./deploy.sh localhost

# Deploy to mainnet with keeper
./deploy.sh mainnet 0x1234567890123456789012345678901234567890

# Deploy to polygon
./deploy.sh polygon

# Deploy to Ethereum Sepolia (using Etherscan API v2)
./deploy.sh sepolia-etherscan    # Etherscan API v2 with chainid=11155111

# Deploy to Base Sepolia (testnet)
./deploy.sh base-sepolia

# Deploy to Base mainnet with keeper
./deploy.sh base 0x1234567890123456789012345678901234567890
```

## Network-Specific Examples

### Local Development
```bash
# Start local node
anvil

# Deploy to local network
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Ethereum Mainnet
```bash
forge script script/Deploy.s.sol --rpc-url https://eth.llamarpc.com --broadcast --verify --etherscan-api-key <API_KEY>
```

### Ethereum Sepolia (Testnet)
```bash
# Using Infura (requires API key)
forge script script/Deploy.s.sol --rpc-url https://sepolia.infura.io/v3/<INFURA_API_KEY> --broadcast --verify --etherscan-api-key <ETHERSCAN_API_KEY>

# Using Etherscan API v2 (requires API key)
forge script script/Deploy.s.sol --rpc-url "https://api.etherscan.io/v2/api?chainid=11155111&apikey=<ETHERSCAN_API_KEY>" --broadcast --verify --etherscan-api-key <ETHERSCAN_API_KEY>
```

### Polygon
```bash
forge script script/Deploy.s.sol --rpc-url https://polygon.llamarpc.com --broadcast --verify --etherscan-api-key <API_KEY>
```

### Arbitrum
```bash
forge script script/Deploy.s.sol --rpc-url https://arb1.arbitrum.io/rpc --broadcast --verify --etherscan-api-key <API_KEY>
```

### Base Sepolia (Testnet)
```bash
forge script script/Deploy.s.sol --rpc-url https://sepolia.base.org --broadcast --verify --etherscan-api-key <BASESCAN_API_KEY>
```

### Base Mainnet
```bash
forge script script/Deploy.s.sol --rpc-url https://mainnet.base.org --broadcast --verify --etherscan-api-key <BASESCAN_API_KEY>
```

## Post-Deployment

After deployment, you can:

1. **Set a keeper** (if not set during deployment):
   ```solidity
   taskManager.setKeeper(keeperAddress);
   ```

2. **Request tasks**:
   ```solidity
   uint256 taskId = taskManager.requestTask(l1Address);
   ```

3. **Complete tasks** (keeper only):
   ```solidity
   taskManager.completeTask(taskId, result);
   ```

4. **Get task results**:
   ```solidity
   bool result = taskManager.getResult(taskId);
   ```

## Security Notes

- Never commit private keys to version control
- Use environment variables or secure key management
- Verify contracts on block explorers after deployment
- Test on testnets before mainnet deployment

## Base Network Information

### Base Sepolia (Testnet)
- **RPC URL**: `https://sepolia.base.org`
- **Chain ID**: 84532
- **Explorer**: https://sepolia.basescan.org
- **Faucet**: https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet

### Base Mainnet
- **RPC URL**: `https://mainnet.base.org`
- **Chain ID**: 8453
- **Explorer**: https://basescan.org
- **Bridge**: https://bridge.base.org

## Troubleshooting

- **"DEPLOYER_PRIVATE_KEY not found"**: Make sure the environment variable is set
- **"Insufficient funds"**: Ensure the deployer account has enough ETH for gas
- **"Transaction failed"**: Check gas limits and network congestion
- **Base network issues**: Ensure you have Base ETH (bridged from Ethereum)
