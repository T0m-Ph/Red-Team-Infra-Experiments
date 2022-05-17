terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

# Configure the AWS Provider
provider "aws" {
  profile = "default"
  region  = var.region
}

# Key Pair
resource "aws_key_pair" "rte-ec2" {
  key_name   = "rte-ec2"
  public_key = file("${var.public_key_loc}")
}