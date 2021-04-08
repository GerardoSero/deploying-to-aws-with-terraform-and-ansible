terraform {
  required_version = ">=0.12.0"
  # backend "s3" {
  #   region  = "us-east-1"
  #   profile = "default"
  #   key     = "terraform_state_file"
  #   bucket  = "terraformstatebucket995551235"
  # }
}

provider "aws" {
  profile = var.profile
  region  = var.main_region
  alias   = "main_region"
}

provider "aws" {
  profile = var.profile
  region  = var.worker_region
  alias   = "worker_region"
}