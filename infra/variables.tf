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

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "resume"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "my_ip" {
  description = "Your public IP address in CIDR format (leave empty to auto-detect)"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
