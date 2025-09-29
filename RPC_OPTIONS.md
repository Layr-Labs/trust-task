# RPC Provider Options

This document outlines the different RPC provider options available for deploying and running the TaskManager system.

## Free Public RPCs (No API Key Required)

These are the recommended options for development and testing:

### Ethereum Networks
- **Mainnet**: `https://eth.llamarpc.com`
- **Sepolia**: 
  - `https://ethereum-sepolia-rpc.publicnode.com` (recommended)
  - `https://sepolia.gateway.tenderly.co`
  - `https://sepolia.drpc.org`

### Layer 2 Networks
- **Polygon**: `https://polygon.llamarpc.com`
- **Arbitrum**: `https://arb1.arbitrum.io/rpc`
- **Base Sepolia**: `https://sepolia.base.org`
- **Base Mainnet**: `https://mainnet.base.org`

## Premium RPC Providers (API Key Required)

For production use or higher rate limits:

### Infura
- **Mainnet**: `https://mainnet.infura.io/v3/<API_KEY>`
- **Sepolia**: `https://sepolia.infura.io/v3/<API_KEY>`

### Alchemy
- **Mainnet**: `https://eth-mainnet.g.alchemy.com/v2/<API_KEY>`
- **Sepolia**: `https://eth-sepolia.g.alchemy.com/v2/<API_KEY>`

### QuickNode
- **Mainnet**: `https://your-endpoint.quiknode.pro/<API_KEY>/`
- **Sepolia**: `https://your-sepolia-endpoint.quiknode.pro/<API_KEY>/`

## Usage Examples

### Deployment Script
```bash
# Using free public RPC
./deploy.sh sepolia-etherscan

# Using Infura (requires INFURA_API_KEY env var)
./deploy.sh sepolia
```

### Bot Configuration
```bash
# Free public RPC (recommended)
export ETHEREUM_RPC_URL="https://eth.llamarpc.com"
export BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"

# Or with Infura
export ETHEREUM_RPC_URL="https://mainnet.infura.io/v3/YOUR_API_KEY"
export BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
```

## Rate Limits

### Free Public RPCs
- **LlamaRPC**: 100 requests/minute
- **Base**: No official limits (reasonable use)

### Premium Providers
- **Infura**: 100,000 requests/day (free tier)
- **Alchemy**: 300M compute units/month (free tier)
- **QuickNode**: Varies by plan

## Recommendations

1. **Development/Testing**: Use free public RPCs
2. **Production**: Use premium providers for reliability
3. **High Volume**: Consider multiple RPC providers for redundancy
4. **Cost Optimization**: Monitor usage and choose appropriate tier

## Troubleshooting

- **Rate Limited**: Switch to premium provider or add delays
- **Connection Issues**: Try alternative RPC endpoints
- **Slow Responses**: Consider using multiple providers with failover
