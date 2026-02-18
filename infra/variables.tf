variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-4"
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
  default     = "mk-uplift-resume-web"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (optional)"
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
