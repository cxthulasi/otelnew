# CloudFront is a global control plane. Lambda, Kinesis, Firehose, and the
# send-your-data secret live in ap-south-1, the AWS region for Coralogix AP1.
provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project = "otelnew"
      System  = "rum-proxy"
    }
  }
}
