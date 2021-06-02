# Connect to our already existing workspace in Terraform Cloud
terraform {
  backend "remote" {
    organization = "AlecApp"
    workspaces {
      name = "LucidHomework"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

