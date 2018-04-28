# DynamoDB table to hold a list of authorzzed; white listed AMIs.
# THis is used by a lambda function which is triggered by EC2 instances
# entering the running state.
#
# You can populate this table using the AWS CLI:
# aws dynamodb put-item --table-name ami_whitelist --item '{"ami_id": {"S": "ami-835b4efa"}, "is_active": {"BOOL": true}}'
#

resource "aws_dynamodb_table" "ami_whitelist" {
  name           = "ami_whitelist"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ami_id"

  attribute {
    name = "ami_id"
    type = "S"

    # Note there is also an is_active` attribute of type `BOOL`,
    # which can not be specified as part of the initial schema.
    # This needs to be added during item creation.
    # https://github.com/terraform-providers/terraform-provider-aws/issues/598
  }
}

output "dynamo_add_item_aws_cli_command" {
  description = "An AWS CLI command to add an item to the DynamoDB table"
value = "aws dynamodb put-item --table-name ${aws_dynamodb_table.ami_whitelist.id} --item '{\"ami_id\": {\"S\": \"ami-835b4efa\"}, \"is_active\": {\"BOOL\": true}}'"
}

