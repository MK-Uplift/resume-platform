# CloudFront distribution in front of ALB API
# This gives us HTTPS for the API without needing a custom domain

resource "aws_cloudfront_distribution" "api" {
  enabled             = true
  comment             = "Resume API via CloudFront HTTPS"
  default_root_object = ""

  origin {
    domain_name = aws_lb.api.dns_name
    origin_id   = "alb-api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-api"
    viewer_protocol_policy = "redirect-to-https"

    # Don't cache API responses
    forwarded_values {
      query_string = true
      headers      = ["Origin", "Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "resume-api-cloudfront"
  }
}

output "api_cloudfront_url" {
  description = "HTTPS URL for the API via CloudFront"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}"
}

output "api_cloudfront_domain" {
  description = "CloudFront domain for the API"
  value       = aws_cloudfront_distribution.api.domain_name
}
