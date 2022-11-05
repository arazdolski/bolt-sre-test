resource "aws_s3_bucket" "b" {
  provider = aws.lawhaxx
  bucket = "bolt-private-bucket-test-4312"
}

resource "aws_s3_bucket" "b2" {
  provider = aws.personal
  bucket = "bolt-private-bucket-test-12321321321"
}


