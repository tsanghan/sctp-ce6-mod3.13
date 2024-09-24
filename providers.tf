terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.66.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "ap-southeast-1"
}
