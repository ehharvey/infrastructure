# Basic PAM functionality leveraging AWS secrets manager as a backend

import os
import json
import boto3
from pathlib import Path

# read API key for aws.json
aws_json = Path('resources/secrets/aws.json').read_text()
aws = json.loads(aws_json)
access_key = aws['access_key']
secret_key = aws['secret_key']

# Initialize secrets manager client
session = boto3.session.Session()
client = session.client(
    service_name='secretsmanager',
    region_name=
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key
