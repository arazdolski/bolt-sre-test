provider "aws" {
  alias = "lawhaxx"
  profile = "lawhaxx"

  default_tags {
    tags = {
      created_by  = "terraform"
    }
  }
}

provider "aws" {
  alias = "personal"
  profile = "personal"
  region = "us-east-1"

  default_tags {
    tags = {
      created_by  = "terraform"
    }
  }
}