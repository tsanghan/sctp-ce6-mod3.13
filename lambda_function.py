import json
import boto3
import os
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Initialize the Secrets Manager client
    client = boto3.client('secretsmanager')

    # Add Environment Variable called SECRET_ID with your secret's ARN
    secret_id = os.getenv('SECRET_ID')

    try:
        # Retrieve the secret
        response = client.get_secret_value(SecretId=secret_id)
        secret = response['SecretString']

        return {
            'statusCode': 200,
            'body': json.dumps({'Secret': secret})
        }

    except ClientError as e:
        return {
            'body': json.dumps({'Error': str(e)})
        }

