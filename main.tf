# variable "cname" {
#   type        = string
#   description = "The alternate domain (CNAME) for CloudFront distribution"
# }

resource "random_id" "origin" {
  byte_length = 8
}

locals {
  s3_origin_id = "s3OriginId-${random_id.origin.id}"
}

resource "aws_cloudfront_origin_access_identity" "s3_access" {
  provider = aws.personal
  comment  = "Restrict access to S3 Content"
}

resource "aws_cloudfront_distribution" "s3_content" {
  provider = aws.personal
  enabled  = true

  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_access.cloudfront_access_identity_path
    }
  }

  #aliases = ["${var.cname}"]

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
}

resource "aws_s3_bucket" "b" {
  provider = aws.lawhaxx
  bucket   = "bolt-sre-test-private-bucket"
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  provider = aws.lawhaxx
  bucket   = aws_s3_bucket.b.id
  policy   = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.b.bucket}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_access.iam_arn]
    }
  }
}
