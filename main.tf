resource "aws_s3_bucket" "b" {
  bucket = "bolt-private-bucket-test"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}


