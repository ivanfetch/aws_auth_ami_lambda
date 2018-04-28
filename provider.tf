provider "aws" {
  version = "~> 1.14"
  region  = "us-west-2"
}

# This is to zip Lambda code for publishing to the Lambda service.
provider "archive" {
  version = "~> 1.0"
}
