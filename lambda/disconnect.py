import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])

def handler(event, context):
    """Handle WebSocket disconnection"""
    connection_id = event['requestContext']['connectionId']
    
    try:
        # Remove connection ID
        table.delete_item(
            Key={
                'connectionId': connection_id
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Disconnected'})
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Failed to disconnect'})
        }
