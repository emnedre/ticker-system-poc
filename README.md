# 📈 Real-Time Stock Ticker System

A scalable, serverless real-time stock ticker system built on AWS. Simulates realistic stock trades with price movements, bid/ask spreads, and volume, then broadcasts them to web clients via WebSocket with smooth animations.

## 🎯 Features

- **Multi-Ticker Support**: Track up to 20 stocks simultaneously (AAPL, TSLA, GOOGL, etc.)
- **Real-Time Updates**: Sub-second latency via WebSocket connections
- **Realistic Simulation**: Random walk with momentum, bid/ask spreads, volume fluctuations
- **Smooth Animations**: Price interpolation with color flashes and easing
- **Serverless Architecture**: Auto-scaling, pay-per-use AWS infrastructure
- **Production-Ready**: Terraform IaC, monitoring, error handling

## 🏗️ Architecture

```
┌─────────────────┐
│  ECS Producers  │  (4 tasks, ARM64, Python)
│  Random tickers │  Generate 5 trades/sec each
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Kinesis Stream  │  (2 shards, 24hr retention)
│  Buffers trades │  2000 records/sec capacity
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Lambda Processor│  (Python 3.13, 512MB)
│  - Store trades │  → DynamoDB (7-day TTL)
│  - Broadcast    │  → API Gateway WebSocket
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ API Gateway WS  │  (100k+ concurrent connections)
│  $connect       │  → Lambda (store connection)
│  $disconnect    │  → Lambda (remove connection)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Web Clients    │  (S3 + CloudFront)
│  HTML/CSS/JS    │  Smooth price animations
└─────────────────┘
```

**Data Flow:**
1. ECS tasks generate realistic trades → Kinesis Stream
2. Lambda processes batches → stores in DynamoDB + broadcasts via WebSocket
3. API Gateway manages connections → routes messages to browsers
4. CloudFront serves static site → browsers display real-time updates

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0
- Docker
- Python 3.11+
- Bash shell

### Deploy

```bash
# Clone repository
git clone https://github.com/yourusername/ticker-system-poc.git
cd ticker-system-poc

# Deploy infrastructure (takes ~10-15 minutes)
./scripts/deploy.sh

# Access your ticker system
# Website URL and WebSocket endpoint will be displayed
```

## 📊 Configuration

### Scale Number of Tickers

```bash
./scripts/scale-tickers.sh 8  # Run 8 tickers simultaneously (max: 20)
```

**Available tickers:** AAPL, TSLA, GOOGL, MSFT, AMZN, META, NVDA, AMD, NFLX, DIS, PYPL, INTC, CSCO, ADBE, CRM, ORCL, IBM, UBER, LYFT, SPOT

### Update Trade Frequency

```bash
./scripts/update-trade-frequency.sh 10  # 10 trades per second
```

### Modify Variables

Edit `variables.tf`:

```hcl
variable "trade_frequency" {
  default = 5  # Trades per second
}

variable "producer_task_count" {
  default = 4  # Number of active tickers
}
```

Apply changes:
```bash
terraform apply
```

## 🎨 Frontend Features

- **Responsive Grid**: Auto-adjusts from 1 to 20 tickers
- **Price Interpolation**: Numbers smoothly count up/down (150ms transition)
- **Visual Feedback**: Green flash on increase, red on decrease
- **Scale Animation**: Subtle pulse effect on price changes
- **Real-Time**: Each ticker updates independently

## 🔧 Trade Simulation

Each producer generates realistic trades:

- **Random Walk**: Prices move with momentum and mean reversion (95% decay)
- **Bid/Ask Spread**: 0.02% spread around current price
- **Volume**: Base 1000 shares with 5% chance of large trades (5-20x)
- **Volatility**: 0.1% price movement per trade
- **Unique Prices**: Each ticker has different starting price ($15-$550)

## 📁 Project Structure

```
.
├── main.tf                 # Terraform provider
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── iam.tf                  # IAM roles and policies
├── vpc.tf                  # VPC and networking
├── ecs.tf                  # ECS cluster and producer
├── kinesis.tf              # Kinesis data stream
├── lambda.tf               # Lambda functions
├── apigateway.tf           # WebSocket API Gateway
├── dynamodb.tf             # DynamoDB tables
├── dynamodb_tickers.tf     # Ticker registry
├── s3.tf                   # S3 bucket for website
├── cloudfront.tf           # CloudFront distribution
├── producer/
│   ├── producer.py         # Trade generator
│   ├── Dockerfile          # Container image (ARM64)
│   └── requirements.txt
├── lambda/
│   ├── connect.py          # WebSocket connect handler
│   ├── disconnect.py       # WebSocket disconnect handler
│   ├── processor.py        # Kinesis stream processor
│   └── requirements.txt
├── frontend/
│   ├── index.html          # Web client
│   └── config.js           # Config template
└── scripts/
    ├── deploy.sh           # Full deployment
    ├── build-producer.sh   # Build Docker image
    ├── package-lambdas.sh  # Package Lambda functions
    ├── scale-tickers.sh    # Scale ticker count
    ├── update-trade-frequency.sh
    ├── init-tickers.sh     # Initialize ticker table
    └── destroy.sh          # Cleanup
```

## 💰 Cost Estimate

Approximate monthly costs (4 tickers, 5 trades/sec):

| Service | Cost |
|---------|------|
| ECS Fargate (4 tasks, ARM64) | $60 |
| Kinesis (2 shards) | $22 |
| Lambda | $5 |
| DynamoDB | $50 |
| API Gateway WebSocket | $3 |
| CloudFront | $1 |
| NAT Gateway | $32 |
| **Total** | **~$173/month** |

### Cost Optimization

1. **Remove trade history**: Save $50/month (comment out `store_trade()` in processor.py)
2. **Use VPC endpoints**: Save $32/month (remove NAT Gateway)
3. **Reduce TTL to 1 day**: Save $40/month (change TTL in processor.py)
4. **Stop when not testing**: Scale ECS tasks to 0

## 📈 Scaling

### Current Capacity
- 100 trades/sec (20 tickers × 5 trades/sec)
- 2 Kinesis shards (2000 records/sec capacity)
- 100k+ WebSocket connections
- 20 concurrent Lambda executions

### Scale Up

**More trades/sec:**
```bash
# Increase Kinesis shards (double at a time)
# Edit kinesis.tf: shard_count = 4
terraform apply
```

**More clients (>1k connections):**
- Implement connection sharding in processor.py
- Use SNS fan-out for parallel broadcasting
- Consider AWS IoT Core for >100k connections

**Global distribution:**
- Deploy to multiple AWS regions
- Use Route 53 for geo-routing
- Enable DynamoDB Global Tables

## 🔍 Monitoring

### View Logs

```bash
# Producer logs
aws logs tail /ecs/ticker-system-poc-producer --follow

# Lambda processor
aws logs tail /aws/lambda/ticker-system-poc-processor --follow
```

### Check Metrics

```bash
# Kinesis throughput
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name IncomingRecords \
  --dimensions Name=StreamName,Value=ticker-system-poc-trades \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

## 🐛 Troubleshooting

**WebSocket not connecting:**
1. Check browser console for errors
2. Verify Lambda functions: `aws lambda list-functions | grep ticker-system-poc`
3. Check API Gateway URL in `frontend/config.js`

**No trades appearing:**
1. Check ECS tasks: `aws ecs list-tasks --cluster ticker-system-poc-cluster`
2. View logs: `aws logs tail /ecs/ticker-system-poc-producer --follow`
3. Verify Kinesis stream: `aws kinesis describe-stream --stream-name ticker-system-poc-trades`

**Frontend not loading:**
1. Wait 10-15 minutes for CloudFront distribution
2. Check S3 bucket: `aws s3 ls s3://ticker-system-poc-website-*/`
3. Try direct S3 URL (shown in Terraform outputs)

## 🧹 Cleanup

```bash
./scripts/destroy.sh
```

Removes all AWS resources and cleans up S3/ECR.

## 🔐 Security

- **Network**: VPC with private subnets for ECS
- **IAM**: Least privilege policies, no hardcoded credentials
- **Data**: TTL for automatic cleanup, HTTPS only
- **Encryption**: Data encrypted at rest and in transit

## ⚠️ Known Limitations

1. **DynamoDB Scan**: Full table scan for connections (optimize with sharding for >1k clients)
2. **Single Region**: No multi-region failover
3. **No Authentication**: WebSocket connections are public
4. **Expensive Writes**: DynamoDB trade history costs $50+/month

## 🎯 Future Enhancements

- Connection sharding for >10k concurrent clients
- User authentication (AWS Cognito)
- Historical charts (store aggregates, not raw trades)
- Price alerts and notifications
- Multi-region deployment
- Custom domain with SSL certificate
- Redis pub/sub for better scaling

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes and test thoroughly
4. Commit: `git commit -m "Add your feature"`
5. Push: `git push origin feature/your-feature`
6. Open a Pull Request

### Development Setup

```bash
# Install dependencies
pip install -r producer/requirements.txt
pip install -r lambda/requirements.txt

# Configure AWS
aws configure

# Deploy to test account
./scripts/deploy.sh
```

### Code Style

- **Python**: Follow PEP 8, use type hints, add docstrings
- **Terraform**: Use consistent naming, add comments
- **JavaScript**: ES6+, meaningful variable names

## 📚 Resources

- [AWS Kinesis Documentation](https://docs.aws.amazon.com/kinesis/)
- [API Gateway WebSocket](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📄 License

MIT License - see LICENSE file for details

---

**Built with AWS, Terraform, and Python** | [Report Bug](https://github.com/yourusername/ticker-system-poc/issues) | [Request Feature](https://github.com/yourusername/ticker-system-poc/issues)
