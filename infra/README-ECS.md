# ECS Fargate Deployment Guide

## Architecture Overview

```
Internet
   ↓
Application Load Balancer (ALB)
   ↓
ECS Fargate Tasks (resume-api container)
   ↓
RDS PostgreSQL
```

## Components

### 1. ECR (Elastic Container Registry)
- Repository: `resume-api`
- Stores Docker images
- Lifecycle policy: keeps last 5 images

### 2. ECS Cluster
- Name: `resume-cluster`
- Container Insights enabled for monitoring

### 3. ECS Task Definition
- Family: `resume-api`
- CPU: 256 (0.25 vCPU)
- Memory: 512 MB
- Container port: 8080
- Secrets: Connection string from AWS Secrets Manager
- Logs: CloudWatch Logs (`/ecs/resume-api`)

### 4. ECS Service
- Name: `resume-api-service`
- Launch type: Fargate (serverless)
- Desired count: 1
- Auto-scaling: Not configured (can be added later)

### 5. Application Load Balancer
- Name: `resume-api-alb`
- Type: Application Load Balancer
- Scheme: Internet-facing
- Listener: HTTP (port 80)
- Target group: `resume-api-tg`
- Health check: `/health` endpoint

### 6. Security Groups
- ALB SG: Allows HTTP/HTTPS from internet
- ECS Tasks SG: Allows traffic from ALB on port 8080
- RDS SG: Allows traffic from ECS tasks on port 5432

## Deployment Steps

### Initial Setup (Terraform)

1. **Apply Terraform configuration:**
   ```bash
   cd infra
   terraform init
   terraform plan
   terraform apply
   ```

2. **Get outputs:**
   ```bash
   terraform output ecr_repository_url
   terraform output alb_dns_name
   terraform output api_url
   ```

### Manual Deployment (CLI)

Use the deployment script:
```bash
cd infra
./deploy-api.sh
```

Or manually:
```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="ap-southeast-4"

# Build and push Docker image
cd Resume.Api
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/resume-api:latest .

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Push image
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/resume-api:latest

# Update ECS service
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --force-new-deployment \
  --region ${AWS_REGION}
```

### Automated Deployment (GitHub Actions)

The `.github/workflows/deploy.yml` workflow automatically:
1. Builds the Docker image
2. Pushes to ECR
3. Updates ECS service
4. Waits for deployment to stabilize

Triggered on:
- Push to `main` branch
- Manual workflow dispatch

## Monitoring

### CloudWatch Logs
```bash
# View logs
aws logs tail /ecs/resume-api --follow --region ap-southeast-4
```

### ECS Service Status
```bash
# Check service status
aws ecs describe-services \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ap-southeast-4
```

### Health Check
```bash
# Get ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names resume-api-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-southeast-4)

# Test health endpoint
curl http://${ALB_DNS}/health

# Test API
curl http://${ALB_DNS}/api/messages
```

## Troubleshooting

### Container won't start
1. Check CloudWatch logs: `/ecs/resume-api`
2. Verify Secrets Manager has correct connection string
3. Check ECS task execution role has Secrets Manager permissions

### Can't connect to database
1. Verify RDS security group allows traffic from ECS tasks SG
2. Check connection string in Secrets Manager
3. Verify RDS is in same VPC as ECS tasks

### ALB health checks failing
1. Check container is listening on port 8080
2. Verify `/health` endpoint returns 200
3. Check ECS tasks security group allows traffic from ALB

### Deployment stuck
```bash
# Force new deployment
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --force-new-deployment \
  --region ap-southeast-4

# Or scale down and up
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --desired-count 0 \
  --region ap-southeast-4

aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --desired-count 1 \
  --region ap-southeast-4
```

## Cost Optimization

Current setup (Free Tier eligible):
- ECS Fargate: ~$10/month (1 task, 0.25 vCPU, 512 MB)
- ALB: ~$16/month (minimum)
- RDS: Free tier (db.t3.micro, 20GB)
- ECR: Free tier (500 MB storage)
- CloudWatch Logs: Free tier (5 GB ingestion)

**Total estimated cost: ~$26/month** (after free tier expires)

To reduce costs:
1. Use RDS Aurora Serverless v2 (pay per use)
2. Implement ECS auto-scaling (scale to 0 during off-hours)
3. Use CloudFront in front of ALB (reduce ALB data transfer)

## Security Best Practices

✅ Secrets stored in AWS Secrets Manager
✅ IAM roles with least privilege
✅ Security groups restrict traffic
✅ Container runs as non-root user
✅ ECR image scanning enabled
✅ CloudWatch logging enabled

## Next Steps

1. **Add HTTPS**: Configure ACM certificate and HTTPS listener
2. **Custom domain**: Route53 + ACM for custom domain
3. **Auto-scaling**: Configure ECS service auto-scaling
4. **Monitoring**: Set up CloudWatch alarms
5. **CI/CD**: Already configured via GitHub Actions
