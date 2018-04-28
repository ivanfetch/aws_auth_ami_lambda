# An SNS topic which Lambda publishes to.
#
# Subscribe to this for testing with an AWS CLI command like:
# aws sns list-topics # To get the ARN of the topic
# aws sns subscribe --topic-arn arn:aws:sns:us-west-2:xxxxxxx:SetGracePeriodiSNSTopic --protocol email --notification-endpoint you@YourDomain.com

resource "aws_sns_topic" "lambda_output_sns" {
  name = "SetGracePeriodiSNSTopic"
}

output "sns_test_subscription_aws_cli_command" {
  description = "An AWS CLI command to test-subscribe an email address to this SNS topic for testing"
  value       = "aws sns subscribe --topic-arn ${aws_sns_topic.lambda_output_sns.arn} --protocol email --notification-endpoint you@YourDomain.com"
}
