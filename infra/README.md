# S3 + CloudFront with OAC

Terraform configuration for creating an S3 bucket and CloudFront distribution with Origin Access Control (OAC).

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create S3 and CloudFront resources

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values (especially `bucket_name` - must be globally unique)

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## What's Created

- S3 bucket with public access blocked
- CloudFront Origin Access Control (OAC)
- CloudFront distribution configured to use OAC
- S3 bucket policy allowing CloudFront to access objects

## Outputs

After applying, you'll get:
- S3 bucket name and ARN
- CloudFront distribution ID and domain name
- CloudFront URL to access your content

## Uploading Content

Upload files to your S3 bucket:
```bash
aws s3 cp index.html s3://your-bucket-name/
```

Access via CloudFront URL (from outputs).
