import { createPublicClient, createWalletClient, http, parseAbi, getContract, formatEther } from 'viem';
import { sepolia, mainnet } from 'viem/chains';
import { mnemonicToAccount } from 'viem/accounts';
import dotenv from 'dotenv';

dotenv.config();

// TaskManager ABI - only the events and functions we need
const TASK_MANAGER_ABI = parseAbi([
  'event TaskRequested(uint256 indexed taskId, address indexed requester, address indexed l1Address, uint8 taskType)',
  'function completeTask(uint256 taskId, bool result) external',
  'function getKeeper() external view returns (address)',
  'function owner() external view returns (address)',
  'function getVerifyTokenAddress() external view returns (address)',
  'function getVerifyDistributionAmount() external view returns (uint256)'
]);

// Task types enum (matching the contract)
enum TaskType {
  BALANCE_CHECK = 0,
  DISTRIBUTE_VERIFY_TOKEN = 1
}

interface TaskRequestedEvent {
  taskId: bigint;
  requester: `0x${string}`;
  l1Address: `0x${string}`;
  taskType: number;
  blockNumber: bigint;
  transactionHash: `0x${string}`;
}

class TaskManagerBot {
  private sepoliaClient: any;
  private ethereumClient: any;
  private walletClient: any;
  private contract: any;
  private isRunning = false;
  private pollInterval = 5000; // 5 seconds

  constructor() {
    // Validate environment variables
    this.validateEnvironment();
    
    // Create clients
    this.setupClients();
    
    // Create contract instance
    this.setupContract();
  }

  private validateEnvironment() {
    const required = [
      'SEPOLIA_RPC_URL',
      'ETHEREUM_RPC_URL', 
      'TASK_MANAGER_CONTRACT_ADDRESS',
      'MNEMONIC'
    ];

    for (const envVar of required) {
      if (!process.env[envVar]) {
        throw new Error(`Missing required environment variable: ${envVar}`);
      }
    }
  }

  private setupClients() {
    // Sepolia client (for listening to events)
    this.sepoliaClient = createPublicClient({
      chain: sepolia,
      transport: http(process.env.SEPOLIA_RPC_URL!)
    });

    // Ethereum mainnet client (for checking balances)
    this.ethereumClient = createPublicClient({
      chain: mainnet,
      transport: http(process.env.ETHEREUM_RPC_URL!)
    });

    // Wallet client for signing transactions
    const account = mnemonicToAccount(process.env.MNEMONIC!);
    
    this.walletClient = createWalletClient({
      account,
      chain: sepolia,
      transport: http(process.env.SEPOLIA_RPC_URL!)
    });

    console.log('✅ Clients initialized');
    console.log('Keeper address:', account.address);
  }

  private setupContract() {
    this.contract = getContract({
      address: process.env.TASK_MANAGER_CONTRACT_ADDRESS! as `0x${string}`,
      abi: TASK_MANAGER_ABI,
      client: this.walletClient
    });

    console.log('✅ Contract initialized at:', process.env.TASK_MANAGER_CONTRACT_ADDRESS);
  }

  async start() {
    console.log('🚀 Starting TaskManager Bot...');
    
    // Verify we're the keeper
    await this.verifyKeeperRole();
    
    this.isRunning = true;
    console.log('✅ Bot started - polling for TaskRequested events on Sepolia...');
    console.log('📋 Supported task types:');
    console.log('   • BALANCE_CHECK - Check Ethereum mainnet balance');
    console.log('   • DISTRIBUTE_VERIFY_TOKEN - Distribute 10 VERIFY tokens if eligible');
    
    // Start polling
    this.pollForEvents();
  }

  private async verifyKeeperRole() {
    try {
      const keeper = await this.contract.read.getKeeper();
      const owner = await this.contract.read.owner();
      const ourAddress = this.walletClient.account.address;
      
      console.log('Contract owner:', owner);
      console.log('Current keeper:', keeper);
      console.log('Our address:', ourAddress);
      
      if (keeper.toLowerCase() !== ourAddress.toLowerCase()) {
        throw new Error(`We are not the keeper! Expected: ${keeper}, Got: ${ourAddress}`);
      }
      
      console.log('✅ Verified as keeper');
      
      // Check VERIFY token balance
      await this.checkContractVerifyTokenBalance();
      
    } catch (error) {
      console.error('❌ Keeper verification failed:', error);
      throw error;
    }
  }

  private async checkContractVerifyTokenBalance() {
    try {
      const verifyTokenAddress = await this.contract.read.getVerifyTokenAddress();
      const verifyTokenBalance = await this.contract.read.getVerifyTokenBalance();
      const distributionAmount = await this.contract.read.getVerifyDistributionAmount();
      
      console.log('🔍 Contract VERIFY token status:');
      console.log(`   Token address: ${verifyTokenAddress}`);
      console.log(`   Contract balance: ${verifyTokenBalance.toString()} VERIFY`);
      console.log(`   Required per distribution: ${distributionAmount.toString()} VERIFY`);
      
      if (verifyTokenBalance < distributionAmount) {
        console.log('⚠️  WARNING: Contract has insufficient VERIFY tokens!');
        console.log('💡 To fund the contract:');
        console.log(`   1. Send VERIFY tokens to: ${process.env.TASK_MANAGER_CONTRACT_ADDRESS}`);
        console.log(`   2. Minimum required: ${distributionAmount.toString()} VERIFY tokens`);
        console.log(`   3. VERIFY token contract: ${verifyTokenAddress}`);
      } else {
        console.log('✅ Contract has sufficient VERIFY tokens for distribution');
      }
    } catch (error) {
      console.log('⚠️  Could not check VERIFY token balance:', error);
    }
  }

  private async pollForEvents() {
    let lastProcessedBlock = await this.sepoliaClient.getBlockNumber();
    
    while (this.isRunning) {
      try {
        const currentBlock = await this.sepoliaClient.getBlockNumber();
        
        if (currentBlock > lastProcessedBlock) {
          console.log(`📦 Checking blocks ${lastProcessedBlock + 1n} to ${currentBlock}`);
          
          // Get TaskRequested events from the last processed block to current
          const events = await this.sepoliaClient.getLogs({
            address: process.env.TASK_MANAGER_CONTRACT_ADDRESS! as `0x${string}`,
            abi: TASK_MANAGER_ABI,
            eventName: 'TaskRequested',
            fromBlock: lastProcessedBlock + 1n,
            toBlock: currentBlock
          }).catch(async (error: any) => {
            console.log('⚠️  Parsed event failed, trying raw logs:', error.message);
            console.log('⚠️  Falling back to raw log decoding with new event format support');
            // Fallback to raw logs with new event signature
            return await this.sepoliaClient.getLogs({
              address: process.env.TASK_MANAGER_CONTRACT_ADDRESS! as `0x${string}`,
              fromBlock: lastProcessedBlock + 1n,
              toBlock: currentBlock,
              topics: [
                '0x33508976c45cd9f575f29ae705abf0357913073cf63cb2dfffad21a8c5b3dceb' // New TaskRequested event signature
              ]
            });
          });

          console.log(`📋 Found ${events.length} events in blocks ${lastProcessedBlock + 1n} to ${currentBlock}`);
          
          for (const event of events) {
            console.log('📨 Processing event:', event);
            await this.processTaskRequestedEvent(event);
          }
          
          lastProcessedBlock = currentBlock;
        }
        
        // Wait before next poll
        await new Promise(resolve => setTimeout(resolve, this.pollInterval));
        
      } catch (error) {
        console.error('❌ Error during polling:', error);
        await new Promise(resolve => setTimeout(resolve, this.pollInterval));
      }
    }
  }

  private async processTaskRequestedEvent(event: any) {
    try {
      console.log('🔍 Raw event data:', JSON.stringify(event, (key, value) => 
        typeof value === 'bigint' ? value.toString() : value, 2));
      
      let taskId, requester, l1Address, taskType;
      
      // Handle parsed events (with args)
      if (event.args) {
        taskId = event.args.taskId;
        requester = event.args.requester;
        l1Address = event.args.l1Address;
        taskType = event.args.taskType;
      } 
      // Handle raw logs (with topics and data)
      else if (event.topics && event.data) {
        // Decode raw log data
        const decoded = this.decodeRawLog(event);
        taskId = decoded.taskId;
        requester = decoded.requester;
        l1Address = decoded.l1Address;
        taskType = decoded.taskType;
      } else {
        console.error('❌ Unknown event format:', event);
        return;
      }
      
      // Validate required fields
      if (!taskId || !requester || !l1Address || taskType === undefined) {
        console.error('❌ Event missing required fields:', { taskId, requester, l1Address, taskType });
        return;
      }
      
      const taskTypeName = this.getTaskTypeName(taskType);
      console.log(`\n🎯 New task detected!`);
      console.log(`Task ID: ${taskId}`);
      console.log(`Requester: ${requester}`);
      console.log(`L1 Address: ${l1Address}`);
      console.log(`Task Type: ${taskTypeName} (${taskType})`);
      
      // Process task based on type
      let result: boolean;
      
      if (taskType === TaskType.BALANCE_CHECK) {
        result = await this.processBalanceCheckTask(l1Address);
      } else if (taskType === TaskType.DISTRIBUTE_VERIFY_TOKEN) {
        result = await this.processVerifyTokenDistributionTask(l1Address);
      } else {
        console.error(`❌ Unknown task type: ${taskType}`);
        return;
      }
      
      console.log(`📊 Task result: ${result ? 'TRUE' : 'FALSE'}`);
      
      // Complete the task
      await this.completeTask(taskId, result);
      
    } catch (error) {
      console.error('❌ Error processing task event:', error);
      console.error('Event data:', event);
    }
  }

  private decodeRawLog(log: any) {
    // For TaskRequested(uint256 indexed taskId, address indexed requester, address indexed l1Address, uint8 taskType)
    // topics[0] = event signature
    // topics[1] = taskId (indexed)
    // topics[2] = requester (indexed) 
    // topics[3] = l1Address (indexed)
    // data = taskType (non-indexed parameter)
    
    console.log('🔍 Decoding raw log with topics:', log.topics);
    console.log('🔍 Raw log data:', log.data);
    
    const oldSignature = '0xa6272efd7bde7dee42c4e060ec63ca6094d2d4bcebfd329e88ee5da23f778d1e';
    const newSignature = '0x33508976c45cd9f575f29ae705abf0357913073cf63cb2dfffad21a8c5b3dceb'; // From the error log
    
    // Try to decode as new format first
    if (log.topics[0] === newSignature) {
      const taskId = BigInt(log.topics[1]);
      const requester = `0x${log.topics[2].slice(26)}`; // Remove 0x and padding
      const l1Address = `0x${log.topics[3].slice(26)}`; // Remove 0x and padding
      
      // Decode taskType from data field (32 bytes, last 8 bits are the uint8)
      const taskType = parseInt(log.data.slice(-2), 16); // Get last 2 hex chars and convert to int
      
      console.log('🔍 Decoded values (new format):', { taskId: taskId.toString(), requester, l1Address, taskType });
      
      return { taskId, requester, l1Address, taskType };
    }
    
    // Try to decode as old format (for backward compatibility)
    if (log.topics[0] === oldSignature) {
      const taskId = BigInt(log.topics[1]);
      const requester = `0x${log.topics[2].slice(26)}`; // Remove 0x and padding
      const l1Address = `0x${log.topics[3].slice(26)}`; // Remove 0x and padding
      const taskType = 0; // Default to BALANCE_CHECK for old format
      
      console.log('🔍 Decoded values (old format):', { taskId: taskId.toString(), requester, l1Address, taskType });
      
      return { taskId, requester, l1Address, taskType };
    }
    
    throw new Error(`Unknown event signature: ${log.topics[0]}. Expected: ${newSignature} (new) or ${oldSignature} (old)`);
  }

  private getTaskTypeName(taskType: number): string {
    switch (taskType) {
      case TaskType.BALANCE_CHECK:
        return 'BALANCE_CHECK';
      case TaskType.DISTRIBUTE_VERIFY_TOKEN:
        return 'DISTRIBUTE_VERIFY_TOKEN';
      default:
        return `UNKNOWN (${taskType})`;
    }
  }

  private async processBalanceCheckTask(l1Address: `0x${string}`): Promise<boolean> {
    console.log(`🔍 Processing BALANCE_CHECK task for address: ${l1Address}`);
    
    // Check Ethereum mainnet balance
    const balance = await this.checkEthereumBalance(l1Address);
    const result = balance > 0n;
    
    console.log(`💰 Ethereum balance: ${formatEther(balance)} ETH`);
    console.log(`📊 Balance check result: ${result ? 'TRUE (has balance)' : 'FALSE (zero balance)'}`);
    
    return result;
  }

  private async processVerifyTokenDistributionTask(l1Address: `0x${string}`): Promise<boolean> {
    console.log(`🔍 Processing DISTRIBUTE_VERIFY_TOKEN task for address: ${l1Address}`);
    
    // For VERIFY token distribution tasks, we need to check if the address is eligible
    // This could be based on various criteria. For now, we'll use a simple check:
    // - Check if the address has any Ethereum mainnet balance (similar to balance check)
    // - Or implement other business logic as needed
    
    const balance = await this.checkEthereumBalance(l1Address);
    const result = balance > 0n;
    
    console.log(`💰 Ethereum balance: ${formatEther(balance)} ETH`);
    console.log(`📊 VERIFY token distribution eligibility: ${result ? 'TRUE (eligible)' : 'FALSE (not eligible)'}`);
    
    if (result) {
      console.log(`🎁 Address ${l1Address} is eligible for VERIFY token distribution`);
      console.log(`💎 10 VERIFY tokens will be distributed upon task completion`);
    } else {
      console.log(`❌ Address ${l1Address} is not eligible for VERIFY token distribution`);
    }
    
    return result;
  }

  private async checkEthereumBalance(address: `0x${string}`): Promise<bigint> {
    try {
      const balance = await this.ethereumClient.getBalance({
        address: address
      });
      return balance;
    } catch (error) {
      console.error('❌ Error checking Ethereum balance:', error);
      throw error;
    }
  }

  private async completeTask(taskId: bigint, result: boolean) {
    try {
      console.log(`🔄 Completing task ${taskId} with result: ${result}`);
      
      // Check contract's VERIFY token balance before attempting completion
      try {
        const verifyTokenBalance = await this.contract.read.getVerifyTokenBalance();
        console.log(`💰 Contract VERIFY token balance: ${verifyTokenBalance.toString()}`);
        
        const distributionAmount = await this.contract.read.getVerifyDistributionAmount();
        console.log(`💎 Required distribution amount: ${distributionAmount.toString()}`);
        
        if (verifyTokenBalance < distributionAmount) {
          console.log(`⚠️  WARNING: Contract has insufficient VERIFY tokens for distribution!`);
          console.log(`⚠️  Balance: ${verifyTokenBalance.toString()}, Required: ${distributionAmount.toString()}`);
        }
      } catch (balanceError) {
        console.log(`⚠️  Could not check VERIFY token balance:`, balanceError);
      }
      
      const hash = await this.contract.write.completeTask([taskId, result]);
      
      console.log(`✅ Task ${taskId} completed! Transaction hash: ${hash}`);
      
      if (result) {
        console.log(`🎉 Task completed successfully - any associated actions (like token distribution) will be executed by the contract`);
      } else {
        console.log(`❌ Task completed with negative result - no additional actions will be taken`);
      }
      
      // Wait for transaction confirmation
      const receipt = await this.sepoliaClient.waitForTransactionReceipt({ hash });
      console.log(`📝 Transaction confirmed in block: ${receipt.blockNumber}`);
      
    } catch (error) {
      console.error(`❌ Error completing task ${taskId}:`, error);
      
      // Check if it's a custom error we can decode
      if (error && typeof error === 'object' && 'cause' in error && error.cause && typeof error.cause === 'object' && 'data' in error.cause) {
        const errorData = (error.cause as any).data;
        console.log(`🔍 Error data: ${errorData}`);
        
        // Try to decode common errors
        if (errorData === '0xe83a55b6') {
          console.log(`❌ Likely error: InsufficientVerifyTokenBalance or VerifyTokenTransferFailed`);
          console.log(`💡 Solution: The contract needs VERIFY tokens to distribute. Please send VERIFY tokens to the contract address.`);
        }
      }
      
      throw error;
    }
  }

  stop() {
    console.log('🛑 Stopping TaskManager Bot...');
    this.isRunning = false;
  }
}

async function main() {
  try {
    const bot = new TaskManagerBot();
    
    // Handle graceful shutdown
    process.on('SIGINT', () => {
      console.log('\n🛑 Received SIGINT, shutting down gracefully...');
      bot.stop();
      process.exit(0);
    });
    
    process.on('SIGTERM', () => {
      console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
      bot.stop();
      process.exit(0);
    });
    
    await bot.start();
    
  } catch (error) {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  }
}

main().catch(console.error);
