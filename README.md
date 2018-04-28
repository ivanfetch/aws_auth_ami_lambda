# AWS Authorized AMIs Lambda

This [Lambda][] function, with supporting [Terraform][] code, publishes to an [SNS][] topic when [EC2][] instances enter a running state which use an [AMI][] that is unapproved. The white listed AMIs are stored in a [DynamoDB][] table, keyed on the AMI ID, with an `is_active` flag to toggle an AMI to be unapproved without removing the AMI from DynamoDB.

A JSON message is sent to the SNS topic, containing the EC2 ID, AMI ID, and account number.

```
{"instance_id": "i-042fd7e9bcd05736a", "ami_id": "ami-835b4efa", "current_account": "123456789012"}
```

The SNS topic can be used to call an HTTP endpoint, send email, or call another Lambda function.

The included Terraform code creates an [IAM][] role and policy for Lambda, an SNS topic, a DynamoDB table, a [CloudWatch rule][] which triggers the Lambda function when EC2 instances enter the _running_ state, and deploys the Lambda function. Once you download [Terraform][], run `terraform plan` in this directory to see what will be created, then `terraform apply` to create the resources. Be sure to save the Terraform `.tfstate` files, as they represent Terraforms knowledge of the resources it has created. Remember to run `terraform destroy` if you're done with these resources - they **could** cost you a few pennies depending  on how much you call the Lambda function.

## Subscribe Something To SNS

You'll need to subscribe something to the SNS topic in order to see what gets published there - if you have the [AWS CLI][] you can use the command suggested in the Terraform outputs - run `terraform output` to re-display those. An example command to subscribe an email address to an SNS topic is `aws sns subscribe --topic-arn arn:aws:sns:us-west-2:xxxxxxx:SetGracePeriodiS  NSTopic --protocol email --notification-endpoint you@YourDomain.com`

## Add AMIs To DynamoDB

You'll also want to populate the DynamoDB table with some AMI IDs - you can use the AWS CLI to quickly add a few entries, there's also a AWS CLI command  suggested via `terraform output` - for example: `aws dynamodb put-item --table-name ami_whitelist --item '{"ami_id": {"S": "ami-835b4efa"}, "is_active": {"BOOL": true}}'`

## Start An EC2 Instance To Test

Start an EC2 instance which uses an AMI that isn't listed in the DynamoDB table, or which has `is_active` set to false for that AMI. You should see a message published to the SNS topic with the AMI ID, EC2 ID, and AWS account number.


[Lambda]: https://aws.amazon.com/lambda/

[Terraform]: http://www.terraform.io

[SNS]: https://docs.aws.amazon.com/sns/latest/dg/welcome.html

[EC2]: https://aws.amazon.com/ec2/details/

[AMI]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html

[DynamoDB]: https://aws.amazon.com/dynamodb/

[IAM]: https://aws.amazon.com/iam/

[CloudWatch rule]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/WhatIsCloudWatchEvents.html

[AWS CLI]: https://aws.amazon.com/cli/
