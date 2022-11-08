variable "cname" {
  type        = string
  description = "The alternate domain (CNAME) for CloudFront distribution"
}

resource "random_id" "origin" {
  byte_length = 8
}

locals {
  s3_origin_id = "s3OriginId-${random_id.origin.id}"
}

resource "aws_cloudfront_origin_access_identity" "s3_access" {
  provider = aws.account_1
  comment  = "Restrict access to S3 Content"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.account_1
  domain_name       = var.cname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "primary" {
  provider = aws.account_1
  name     = var.cname
}

resource "aws_route53_record" "validation" {
  provider = aws.account_1
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_route53_record" "redirect_to_cloudfront" {
  provider = aws.account_1
  zone_id  = aws_route53_zone.primary.zone_id
  name     = var.cname
  type     = "A"

  alias {
    name = aws_cloudfront_distribution.s3_content.domain_name
    zone_id  = aws_cloudfront_distribution.s3_content.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate_validation" "default" {
  provider                = aws.account_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_cloudfront_distribution" "s3_content" {
  provider = aws.account_1
  enabled  = true

  origin {
    domain_name = aws_s3_bucket.private.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_access.cloudfront_access_identity_path
    }
  }

  aliases = [var.cname]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
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

resource "aws_s3_bucket" "private" {
  provider = aws.account_2
  bucket   = "bolt-sre-test-bucket"
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  provider = aws.account_2
  bucket   = aws_s3_bucket.private.id
  policy   = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.private.bucket}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_access.iam_arn]
    }
  }
}
