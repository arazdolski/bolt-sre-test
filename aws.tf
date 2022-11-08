provider "aws" {
  alias = "account_2"
  profile = "account_2"

  default_tags {
    tags = {
      created_by  = "terraform"
    }
  }
}

provider "aws" {
  alias = "account_1"
  profile = "account_1"
  region = "us-east-1"

  default_tags {
    tags = {
      created_by  = "terraform"
    }
  }
}