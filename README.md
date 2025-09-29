# Trust Task

A decentralized task management system that uses on-chain task requests and off-chain oracle verification.

## Overview

This project consists of:

1. **Smart Contract** (`onchain/`): A TaskManager contract deployed on Sepolia testnet that accepts Ethereum addresses as task requests
2. **Backend Bot** (`src/`): A TypeScript application designed to run in a TEE (Trusted Execution Environment) on EigenCloud

## How It Works

1. **Task Submission**: Users submit Ethereum addresses to the TaskManager contract on Sepolia
2. **Event Monitoring**: The backend bot listens for `TaskRequested` events from the contract
3. **Oracle Verification**: For each task, the bot checks if the submitted address has a non-zero balance on Ethereum mainnet L1
4. **Result Submission**: The bot posts the verification result (true/false) back to the contract on Sepolia

## Architecture

- **Sepolia Testnet**: Hosts the TaskManager contract for task requests and results
- **Ethereum Mainnet**: Source of truth for balance verification
- **EigenCloud TEE**: Secure environment for running the oracle bot
- **Multi-chain**: Bot interacts with both Sepolia (contract) and Ethereum mainnet (balance checks)

## Development

### Setup & Local Testing
```bash
npm install
cp .env.example .env
npm run dev
```

### Docker Testing
```bash
docker build -t my-app .
docker run --rm --env-file .env my-app
```
