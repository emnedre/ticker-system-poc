import json
import os
import boto3
import time

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])

def handler(event, context):
    """Handle WebSocket connection"""
    connection_id = event['requestContext']['connectionId']
    
    try:
        # Store connection ID with TTL (24 hours)
        table.put_item(
            Item={
                'connectionId': connection_id,
                'timestamp': int(time.time()),
                'ttl': int(time.time()) + 86400
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Connected'})
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Failed to connect'})
        }
