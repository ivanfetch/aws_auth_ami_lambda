# Lambda function and CloudWatch event / rule,
# to publish to SNS if an EC2 instance uses an unapproved AMI.

# Zip the Lambda code to be deployed to the Lambda service.
data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_dir  = "${path.root}/lambda-code"
  output_path = "${path.root}/tmp/lambda.zip"
}

resource "aws_lambda_function" "auth_ami" {
  function_name = "authorized_amis"
  runtime       = "python2.7"
  handler       = "auth_ami.lambda_handler"

  # THis role is defined in the iam.tf file.
  role             = "${aws_iam_role.lambda_role.arn}"
  timeout          = 20
  filename         = "${path.root}/tmp/lambda.zip"
  source_code_hash = "${data.archive_file.lambda_zip_file.output_base64sha256}"

  # Pass the SNS topic ARN and DynamoDB table name in the environment.
  environment {
    variables = {
      sns_arn           = "${aws_sns_topic.lambda_output_sns.arn}"
      dynamo_table_name = "${aws_dynamodb_table.ami_whitelist.id}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "running_ec2" {
  name        = "running-ec2-lambda"
  description = "Trigger Lambda to determine if an AMI is authorized when an EC2 instance is started"

  event_pattern = <<EOF
{
  "source": [ "aws.ec2" ],
  "detail-type": [ "EC2 Instance State-change Notification" ],
  "detail": {
    "state": [ "running" ]
  }
}
  EOF
}

# Link the Lambda function to the CloudWatch event / rule.
resource "aws_cloudwatch_event_target" "cloudwatch_to_lambda" {
  rule      = "${aws_cloudwatch_event_rule.running_ec2.name}"
  target_id = "lambda-target"
  arn       = "${aws_lambda_function.auth_ami.arn}"
}

resource "aws_lambda_permission" "cloudwatch_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.auth_ami.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.running_ec2.arn}"
}
