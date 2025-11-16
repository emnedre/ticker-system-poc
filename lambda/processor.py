import json
import os
import base64
import boto3
from decimal import Decimal

# AWS clients
dynamodb = boto3.resource('dynamodb')
trades_table = dynamodb.Table(os.environ['TRADES_TABLE'])
connections_table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])
apigateway = boto3.client('apigatewaymanagementapi', 
                          endpoint_url=os.environ['WEBSOCKET_API_ENDPOINT'])

def handler(event, context):
    """Process trades from Kinesis and broadcast to WebSocket clients"""
    
    trades_by_symbol = {}
    
    # Process all trades in the batch, keeping only latest per symbol
    for record in event['Records']:
        # Decode Kinesis record
        payload = base64.b64decode(record['kinesis']['data'])
        trade = json.loads(payload)
        
        # Keep only the latest trade per symbol
        trades_by_symbol[trade['symbol']] = trade
        
        # Store in DynamoDB (optional - consider removing for cost savings)
        store_trade(trade)
    
    # Broadcast latest trade for each symbol
    for trade in trades_by_symbol.values():
        broadcast_to_clients(trade)
    
    return {
        'statusCode': 200,
        'body': json.dumps({'message': f'Processed {len(trades_by_symbol)} unique symbols'})
    }

def store_trade(trade):
    """Store trade in DynamoDB"""
    try:
        trades_table.put_item(
            Item={
                'symbol': trade['symbol'],
                'timestamp': Decimal(str(trade['timestamp'])),
                'price': Decimal(str(trade['price'])),
                'volume': trade['volume'],
                'bid': Decimal(str(trade['bid'])),
                'ask': Decimal(str(trade['ask'])),
                'ttl': int(trade['timestamp']) + 604800  # 7 days TTL
            }
        )
    except Exception as e:
        print(f"Error storing trade: {str(e)}")



def broadcast_to_clients(trade):
    """Broadcast trade update to all WebSocket connections"""
    try:
        # Get all active connections (TODO: optimize with connection sharding for >1k connections)
        response = connections_table.scan()
        connections = response.get('Items', [])
        
        if not connections:
            return  # No clients connected
        
        # Prepare message once
        message = json.dumps({
            'type': 'trade',
            'data': trade
        }).encode('utf-8')
        
        # Send to each connection
        dead_connections = []
        for connection in connections:
            connection_id = connection['connectionId']
            try:
                apigateway.post_to_connection(
                    ConnectionId=connection_id,
                    Data=message
                )
            except apigateway.exceptions.GoneException:
                # Connection is dead, mark for removal
                dead_connections.append(connection_id)
            except Exception as e:
                print(f"Error sending to {connection_id}: {str(e)}")
        
        # Clean up dead connections in batch
        if dead_connections:
            print(f"Cleaning up {len(dead_connections)} dead connections")
            for connection_id in dead_connections:
                try:
                    connections_table.delete_item(
                        Key={'connectionId': connection_id}
                    )
                except Exception as e:
                    print(f"Error deleting connection {connection_id}: {str(e)}")
                
    except Exception as e:
        print(f"Error broadcasting: {str(e)}")
