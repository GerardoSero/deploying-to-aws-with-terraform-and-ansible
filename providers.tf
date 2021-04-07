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