# Environment Variables

The TaskManager Bot requires the following environment variables to be set:

## Required Variables

```bash
# Sepolia RPC URL for listening to TaskRequested events
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com

# Ethereum mainnet RPC URL for checking balances
# Option 1: Free public RPC (recommended)
ETHEREUM_RPC_URL=https://eth.llamarpc.com

# Option 2: Infura (requires API key)
# ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY

# Option 3: Alchemy (requires API key)
# ETHEREUM_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY

# TaskManager contract address on Sepolia
TASK_MANAGER_CONTRACT_ADDRESS=0x51eaF1d31d422E501995e6b61f40F0513f82Cc65

```

## Optional Variables

```bash
# Custom polling interval in milliseconds (default: 5000)
POLL_INTERVAL=5000
```

## Setup Instructions

1. Copy the required variables to your `.env` file
2. Replace the placeholder values with your actual configuration
3. Make sure the keeper account has Sepolia ETH for gas fees
4. Ensure the keeper account is set as the keeper in the TaskManager contract

## Example .env file

```bash
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
ETHEREUM_RPC_URL=https://eth.llamarpc.com
TASK_MANAGER_CONTRACT_ADDRESS=0x51eaF1d31d422E501995e6b61f40F0513f82Cc65
MNEMONIC=abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
POLL_INTERVAL=5000
```

## Security Notes

- Never commit your `.env` file to version control
- Use a dedicated keeper account with minimal funds
- Consider using a hardware wallet for production deployments
- Regularly rotate your private keys
