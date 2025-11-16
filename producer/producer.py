import os
import json
import time
import random
import boto3
import uuid
from datetime import datetime

# Configuration from environment variables
KINESIS_STREAM_NAME = os.environ['KINESIS_STREAM_NAME']
AWS_REGION = os.environ['AWS_REGION']
TRADE_FREQUENCY = float(os.environ.get('TRADE_FREQUENCY', 5))
TICKERS_TABLE = os.environ['TICKERS_TABLE']

# Initialize AWS clients
kinesis = boto3.client('kinesis', region_name=AWS_REGION)
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
tickers_table = dynamodb.Table(TICKERS_TABLE)

# Unique task ID for this producer instance
TASK_ID = str(uuid.uuid4())[:8]

class RealisticTradeGenerator:
    """Generates realistic stock trades with price movements"""
    
    def __init__(self, symbol, initial_price):
        self.symbol = symbol
        self.current_price = initial_price
        self.bid_ask_spread_pct = 0.0002  # 0.02% spread
        self.volatility = 0.001  # Price volatility per trade
        self.momentum = 0.0  # Current price momentum
        self.volume_base = 1000
        
    def generate_trade(self):
        """Generate a realistic trade"""
        
        # Update momentum (mean-reverting random walk)
        momentum_change = random.gauss(0, 0.0005)
        self.momentum = self.momentum * 0.95 + momentum_change
        
        # Calculate price change
        price_change = random.gauss(self.momentum, self.volatility)
        self.current_price *= (1 + price_change)
        
        # Ensure price stays positive and reasonable
        self.current_price = max(self.current_price, 1.0)
        
        # Calculate bid/ask spread
        spread = self.current_price * self.bid_ask_spread_pct
        bid = self.current_price - spread / 2
        ask = self.current_price + spread / 2
        
        # Generate volume (with occasional large trades)
        if random.random() < 0.05:  # 5% chance of large trade
            volume = int(self.volume_base * random.uniform(5, 20))
        else:
            volume = int(self.volume_base * random.uniform(0.5, 2))
        
        # Create trade object
        trade = {
            'symbol': self.symbol,
            'timestamp': time.time(),
            'price': round(self.current_price, 2),
            'bid': round(bid, 2),
            'ask': round(ask, 2),
            'volume': volume,
            'datetime': datetime.utcnow().isoformat()
        }
        
        return trade
    
    def get_current_state(self):
        """Get current ticker state"""
        return {
            'symbol': self.symbol,
            'price': round(self.current_price, 2),
            'momentum': round(self.momentum * 100, 4)
        }

def send_to_kinesis(trade):
    """Send trade to Kinesis stream"""
    try:
        response = kinesis.put_record(
            StreamName=KINESIS_STREAM_NAME,
            Data=json.dumps(trade),
            PartitionKey=trade['symbol']
        )
        return response
    except Exception as e:
        print(f"Error sending to Kinesis: {str(e)}")
        return None

def get_random_ticker():
    """Get a random ticker from DynamoDB"""
    print(f"Task {TASK_ID}: Selecting random ticker...")
    
    try:
        response = tickers_table.scan()
        tickers = response.get('Items', [])
        
        if not tickers:
            print("No tickers found in table!")
            return None
        
        # Pick a random ticker
        ticker = random.choice(tickers)
        print(f"Task {TASK_ID}: Selected ticker {ticker['symbol']}")
        return ticker
        
    except Exception as e:
        print(f"Error getting ticker: {str(e)}")
        return None

def main():
    """Main producer loop"""
    # Get a random ticker
    ticker = get_random_ticker()
    if not ticker:
        print("No tickers found. Exiting.")
        return
    
    symbol = ticker['symbol']
    initial_price = float(ticker['initialPrice'])
    
    print(f"Task {TASK_ID}: Starting trade producer for {symbol}")
    print(f"Initial price: ${initial_price}")
    print(f"Trade frequency: {TRADE_FREQUENCY} trades/second")
    print(f"Kinesis stream: {KINESIS_STREAM_NAME}")
    
    generator = RealisticTradeGenerator(symbol, initial_price)
    
    # Calculate sleep time between trades
    sleep_time = 1.0 / TRADE_FREQUENCY
    
    trade_count = 0
    start_time = time.time()
    
    try:
        while True:
            # Generate and send trade
            trade = generator.generate_trade()
            response = send_to_kinesis(trade)
            
            if response:
                trade_count += 1
                
                # Log every 10 trades
                if trade_count % 10 == 0:
                    elapsed = time.time() - start_time
                    rate = trade_count / elapsed
                    state = generator.get_current_state()
                    print(f"Trades: {trade_count} | Rate: {rate:.2f}/s | "
                          f"Price: ${state['price']} | Momentum: {state['momentum']}%")
            
            # Sleep until next trade
            time.sleep(sleep_time)
            
    except KeyboardInterrupt:
        print("\nShutting down producer...")
        elapsed = time.time() - start_time
        print(f"Total trades: {trade_count} in {elapsed:.1f}s")
    except Exception as e:
        print(f"Error in main loop: {str(e)}")
        raise

if __name__ == '__main__':
    main()
