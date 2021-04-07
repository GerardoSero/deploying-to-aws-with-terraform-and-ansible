terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region  = "us-east-1"
    profile = "default"
    key     = "terraform_state_file"
    bucket  = "terraformstatebucket995551235"
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region_main
  alias   = "region_main"
}

provider "aws" {
  profile = var.profile
  region  = var.region_worker
  alias   = "region_worker"
}