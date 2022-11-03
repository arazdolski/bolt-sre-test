provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      created_by  = "terraform"
    }
  }
}