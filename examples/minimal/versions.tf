terraform {
  required_version = ">= 1.10.7" // Open tofu 1.10.7

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.86"
    }
  }
}

provider "scaleway" {}
