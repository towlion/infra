terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "digitalocean" {}

provider "aws" {
  region                      = var.region != "" ? var.region : "us-east-1"
  skip_credentials_validation = var.cloud_provider != "aws"
  skip_requesting_account_id  = var.cloud_provider != "aws"
  skip_metadata_api_check     = var.cloud_provider != "aws"
  access_key                  = var.cloud_provider != "aws" ? "unused" : null
  secret_key                  = var.cloud_provider != "aws" ? "unused" : null
}
