# Pyhon 2.7 Lambda Function
#
# Publish to an SNS topic if a running EC2 instance is using an unapproved AMI.
# The EC2 ID, AMi ID, and AWS account number are published to SNS.
# Whitelisted AMIs are listed in a DynamoDB table.
# The DynamoDB table has an ami_id key, and an is_active boolean,
# is_active must be True for an AMI to be whitelisted.
# THe following environment variables should be set in the Lambda function:
#   sns_arn - the ARN of the SNS topic
#   dynamo_table_name - the name of the DynamoDB table

from __future__ import print_function
import json
import boto3
import os
import logging

sns_arn = os.environ.get('sns_arn')
dynamo_table_name = os.environ.get('dynamo_table_name')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    publish_to_sns = False
    logger.info("Received event: " + str(event))

    try:
        region = event['region']
        detail = event['detail']
        instance_id = detail['instance-id']
        ec2 = boto3.resource('ec2')
        instance = ec2.Instance(instance_id)
        ami_id = instance.image_id

        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(dynamo_table_name)
        try:
            logger.info("Determining whether AMI " + ami_id + " is white listed for instance " + instance_id + " in account " + event['account'])
            dynamodb_response = table.get_item(
                Key={
                    'ami_id': ami_id
                }
            )
        except Exception as e:
            print("There was an error getting the AMI ID item " + ami_id + " from DynamoDB: " + e.response['Error']['Message'])
        else:
            if not 'Item' in dynamodb_response:
                logger.info("Could not find AMI " + ami_id + " in the DynamoDB table " + dynamo_table_name)
                publish_to_sns = True
            else:
                whitelisted_ami = dynamodb_response['Item']
                if whitelisted_ami['is_active']:
                    logger.info("AMI " + whitelisted_ami['ami_id'] + " is marked active in DynamoDB")
                else:
                    logger.info("AMI " + whitelisted_ami['ami_id'] + " is not marked active in DynamoDB")
                    publish_to_sns = True

            if publish_to_sns is True:
                message = {"instance_id": instance_id, "current_account": event['account'], "ami_id": ami_id}
                sns = boto3.client('sns')
                try:
                    logger.info("Publishing this message to SNS topic " + sns_arn + "...: " + json.dumps(message))
                    sns_response = sns.publish(
                        TargetArn=sns_arn,
                        Message=json.dumps({'default': json.dumps(message)}),
                        MessageStructure='json'
                    )
                except Exception as e:
                    print("There was an error publishing to the SNS topic " + sns_arn + "...: " + e.response['Error']['Message'])
            logger.info("Done processing AMI " + ami_id + " for instance " + instance_id + " in account " + event['account'])
    except Exception as e:
        logger.error('Something went wrong: ' + str(e))

