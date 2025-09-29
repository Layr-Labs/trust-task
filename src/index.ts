import { createPublicClient, createWalletClient, http, parseAbi, getContract, formatEther } from 'viem';
import { sepolia, mainnet } from 'viem/chains';
import { mnemonicToAccount } from 'viem/accounts';
import dotenv from 'dotenv';

dotenv.config();

// TaskManager ABI - only the events and functions we need
const TASK_MANAGER_ABI = parseAbi([
  'event TaskRequested(uint256 indexed taskId, address indexed requester, address indexed l1Address)',
  'function completeTask(uint256 taskId, bool result) external',
  'function getKeeper() external view returns (address)',
  'function owner() external view returns (address)'
]);

interface TaskRequestedEvent {
  taskId: bigint;
  requester: `0x${string}`;
  l1Address: `0x${string}`;
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
    } catch (error) {
      console.error('❌ Keeper verification failed:', error);
      throw error;
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
            // Fallback to raw logs
            return await this.sepoliaClient.getLogs({
              address: process.env.TASK_MANAGER_CONTRACT_ADDRESS! as `0x${string}`,
              fromBlock: lastProcessedBlock + 1n,
              toBlock: currentBlock,
              topics: [
                '0xa6272efd7bde7dee42c4e060ec63ca6094d2d4bcebfd329e88ee5da23f778d1e' // TaskRequested event signature
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
      
      let taskId, requester, l1Address;
      
      // Handle parsed events (with args)
      if (event.args) {
        taskId = event.args.taskId;
        requester = event.args.requester;
        l1Address = event.args.l1Address;
      } 
      // Handle raw logs (with topics and data)
      else if (event.topics && event.data) {
        // Decode raw log data
        const decoded = this.decodeRawLog(event);
        taskId = decoded.taskId;
        requester = decoded.requester;
        l1Address = decoded.l1Address;
      } else {
        console.error('❌ Unknown event format:', event);
        return;
      }
      
      // Validate required fields
      if (!taskId || !requester || !l1Address) {
        console.error('❌ Event missing required fields:', { taskId, requester, l1Address });
        return;
      }
      
      console.log(`\n🎯 New task detected!`);
      console.log(`Task ID: ${taskId}`);
      console.log(`Requester: ${requester}`);
      console.log(`L1 Address to check: ${l1Address}`);
      
      // Check Ethereum mainnet balance
      const balance = await this.checkEthereumBalance(l1Address);
      const result = balance > 0n;
      
      console.log(`💰 Ethereum balance: ${formatEther(balance)} ETH`);
      console.log(`📊 Task result: ${result ? 'TRUE (has balance)' : 'FALSE (zero balance)'}`);
      
      // Complete the task
      await this.completeTask(taskId, result);
      
    } catch (error) {
      console.error('❌ Error processing task event:', error);
      console.error('Event data:', event);
    }
  }

  private decodeRawLog(log: any) {
    // For TaskRequested(uint256 indexed taskId, address indexed requester, address indexed l1Address)
    // topics[0] = event signature (0xa6272efd7bde7dee42c4e060ec63ca6094d2d4bcebfd329e88ee5da23f778d1e)
    // topics[1] = taskId (indexed)
    // topics[2] = requester (indexed) 
    // topics[3] = l1Address (indexed)
    
    console.log('🔍 Decoding raw log with topics:', log.topics);
    
    // Verify this is a TaskRequested event
    const expectedSignature = '0xa6272efd7bde7dee42c4e060ec63ca6094d2d4bcebfd329e88ee5da23f778d1e';
    if (log.topics[0] !== expectedSignature) {
      throw new Error(`Unexpected event signature: ${log.topics[0]}, expected: ${expectedSignature}`);
    }
    
    const taskId = BigInt(log.topics[1]);
    const requester = `0x${log.topics[2].slice(26)}`; // Remove 0x and padding
    const l1Address = `0x${log.topics[3].slice(26)}`; // Remove 0x and padding
    
    console.log('🔍 Decoded values:', { taskId: taskId.toString(), requester, l1Address });
    
    return { taskId, requester, l1Address };
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
      
      const hash = await this.contract.write.completeTask([taskId, result]);
      
      console.log(`✅ Task ${taskId} completed! Transaction hash: ${hash}`);
      
      // Wait for transaction confirmation
      const receipt = await this.sepoliaClient.waitForTransactionReceipt({ hash });
      console.log(`📝 Transaction confirmed in block: ${receipt.blockNumber}`);
      
    } catch (error) {
      console.error(`❌ Error completing task ${taskId}:`, error);
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
