# SES is not available in ap-southeast-4, use ap-southeast-2 (Sydney)
resource "aws_ses_email_identity" "notify" {
  provider = aws.ses
  email    = "mkuplift11@gmail.com"
}

output "ses_identity_arn" {
  value = aws_ses_email_identity.notify.arn
}
