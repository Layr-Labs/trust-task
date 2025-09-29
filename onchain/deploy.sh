#!/bin/bash

# TaskManager Deployment Script
# Usage: ./deploy.sh <network> [keeper_address]

set -e

# Check if DEPLOYER_PRIVATE_KEY is set
if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "Error: DEPLOYER_PRIVATE_KEY environment variable is not set"
    echo "Please set it with: export DEPLOYER_PRIVATE_KEY='your_private_key_here'"
    exit 1
fi

# Get network from first argument
NETWORK=${1:-"localhost"}
KEEPER_ADDRESS=${2:-""}

# Set RPC URLs based on network
case $NETWORK in
    "localhost"|"local")
        RPC_URL="http://localhost:8545"
        VERIFY=""
        ;;
    "mainnet"|"eth")
        RPC_URL="https://eth.llamarpc.com"
        VERIFY="--verify --etherscan-api-key $ETHERSCAN_API_KEY"
        ;;
    "polygon")
        RPC_URL="https://polygon.llamarpc.com"
        VERIFY="--verify --etherscan-api-key $POLYGONSCAN_API_KEY"
        ;;
    "arbitrum")
        RPC_URL="https://arb1.arbitrum.io/rpc"
        VERIFY="--verify --etherscan-api-key $ARBISCAN_API_KEY"
        ;;
    "sepolia"|"sepolia_etherscan")
        RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"
        VERIFY="--verify --etherscan-api-key $ETHERSCAN_API_KEY"
        ;;
    "base-sepolia"|"base_sepolia")
        RPC_URL="https://sepolia.base.org"
        VERIFY="--verify --etherscan-api-key $BASESCAN_API_KEY"
        ;;
    "base")
        RPC_URL="https://mainnet.base.org"
        VERIFY="--verify --etherscan-api-key $BASESCAN_API_KEY"
        ;;
    *)
        echo "Error: Unknown network '$NETWORK'"
        echo "Supported networks: localhost, mainnet, polygon, arbitrum, sepolia, sepolia-etherscan, sepolia-tenderly, sepolia-drpc, base-sepolia, base"
        exit 1
        ;;
esac

echo "🚀 Deploying TaskManager to $NETWORK..."
echo "RPC URL: $RPC_URL"

# Set keeper address if provided
if [ -n "$KEEPER_ADDRESS" ]; then
    export KEEPER_ADDRESS
    echo "Keeper address: $KEEPER_ADDRESS"
    forge script script/DeployTaskManagerWithKeeper.s.sol --rpc-url $RPC_URL --broadcast $VERIFY
else
    echo "No keeper address provided - deployer will be owner"
    forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast $VERIFY
fi

echo "✅ Deployment complete!"
