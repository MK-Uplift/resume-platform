# Quick Reference - Resume Platform

## 🔗 URLs

| Service | URL |
|---------|-----|
| Frontend | https://ddcfte7n5r9tt.cloudfront.net |
| API (ALB) | Run: `terraform output api_url` |
| RDS Endpoint | resume-db.cpqckaaqa750.ap-southeast-4.rds.amazonaws.com |

## 🚀 Quick Commands

### Deploy Everything
```bash
./deploy-day4.sh
```

### Deploy API Only
```bash
cd infra
./deploy-api.sh
```

### View API Logs
```bash
aws logs tail /ecs/resume-api --follow --region ap-southeast-4
```

### Test API
```bash
# Get ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers --names resume-api-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-southeast-4)

# Health check
curl http://${ALB_DNS}/health

# Get messages
curl http://${ALB_DNS}/api/messages

# Post message
curl -X POST http://${ALB_DNS}/api/messages \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","message":"Hello!"}'
```

### Terraform Commands
```bash
cd infra

# Plan changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output

# Get specific output
terraform output api_url
terraform output db_password
terraform output ecr_repository_url
```

### Docker Commands
```bash
cd Resume.Api

# Build locally
docker build -t resume-api:local .

# Run locally (replace connection string)
docker run -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="YOUR_CONNECTION_STRING" \
  resume-api:local

# Test local container
curl http://localhost:8080/health
```

### ECS Commands
```bash
# List clusters
aws ecs list-clusters --region ap-southeast-4

# Describe service
aws ecs describe-services \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ap-southeast-4

# List tasks
aws ecs list-tasks \
  --cluster resume-cluster \
  --service-name resume-api-service \
  --region ap-southeast-4

# Force new deployment
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --force-new-deployment \
  --region ap-southeast-4

# Scale service
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --desired-count 2 \
  --region ap-southeast-4
```

### ECR Commands
```bash
# List repositories
aws ecr describe-repositories --region ap-southeast-4

# List images
aws ecr list-images \
  --repository-name resume-api \
  --region ap-southeast-4

# Login to ECR
aws ecr get-login-password --region ap-southeast-4 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-southeast-4.amazonaws.com
```

### ALB Commands
```bash
# List load balancers
aws elbv2 describe-load-balancers --region ap-southeast-4

# Get ALB DNS
aws elbv2 describe-load-balancers \
  --names resume-api-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-southeast-4

# Check target health
TG_ARN=$(aws elbv2 describe-target-groups \
  --names resume-api-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region ap-southeast-4)

aws elbv2 describe-target-health \
  --target-group-arn ${TG_ARN} \
  --region ap-southeast-4
```

### RDS Commands
```bash
# Describe DB instance
aws rds describe-db-instances \
  --db-instance-identifier resume-db \
  --region ap-southeast-4

# Get connection info
terraform output rds_endpoint
terraform output db_password
```

### Secrets Manager Commands
```bash
# List secrets
aws secretsmanager list-secrets --region ap-southeast-4

# Get secret value
aws secretsmanager get-secret-value \
  --secret-id resume-rds-credentials \
  --region ap-southeast-4
```

### CloudWatch Logs Commands
```bash
# Tail logs (real-time)
aws logs tail /ecs/resume-api --follow --region ap-southeast-4

# View last hour
aws logs tail /ecs/resume-api --since 1h --region ap-southeast-4

# Filter errors
aws logs tail /ecs/resume-api \
  --since 1h \
  --filter-pattern "ERROR" \
  --region ap-southeast-4

# List log streams
aws logs describe-log-streams \
  --log-group-name /ecs/resume-api \
  --region ap-southeast-4
```

### Local Development
```bash
# Run API locally
cd Resume.Api
dotnet run

# Run frontend locally
cd Resume.Web
dotnet run

# Run migrations
cd Resume.Api
dotnet ef database update

# Create new migration
dotnet ef migrations add MigrationName
```

### Git Commands
```bash
# Commit and push (triggers CI/CD)
git add .
git commit -m "Day 4: Add API containerization and ECS deployment"
git push origin main

# Check GitHub Actions status
gh run list
gh run watch
```

## 📊 Resource Names

| Type | Name |
|------|------|
| S3 Bucket | mk-uplift-resume-web |
| CloudFront Distribution | E1XRRA7RBLQI4C |
| RDS Instance | resume-db |
| ECR Repository | resume-api |
| ECS Cluster | resume-cluster |
| ECS Service | resume-api-service |
| ALB | resume-api-alb |
| Target Group | resume-api-tg |
| Log Group | /ecs/resume-api |
| Secret | resume-rds-credentials |

## 🔐 IAM Policies Required

- AmazonEC2FullAccess
- AmazonRDSFullAccess
- AmazonS3FullAccess
- CloudFrontFullAccess
- AmazonECS_FullAccess
- AmazonEC2ContainerRegistryFullAccess
- IAMFullAccess
- CloudWatchLogsFullAccess
- ElasticLoadBalancingFullAccess
- SecretsManagerReadWrite

## 📁 Important Files

| File | Purpose |
|------|---------|
| `Resume.Api/Dockerfile` | Docker image definition |
| `infra/ecs.tf` | ECS configuration |
| `infra/alb.tf` | Load balancer configuration |
| `infra/ecr.tf` | Container registry |
| `.github/workflows/deploy.yml` | CI/CD pipeline |
| `Resume.Web/Pages/Index.razor` | Frontend with contact form |

## 🐛 Troubleshooting

### Container won't start
```bash
# Check logs
aws logs tail /ecs/resume-api --follow --region ap-southeast-4

# Check task status
aws ecs describe-tasks \
  --cluster resume-cluster \
  --tasks $(aws ecs list-tasks --cluster resume-cluster --service-name resume-api-service --query 'taskArns[0]' --output text) \
  --region ap-southeast-4
```

### Database connection issues
```bash
# Test from local
psql -h resume-db.cpqckaaqa750.ap-southeast-4.rds.amazonaws.com -U postgres -d resume

# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=resume-rds-sg" \
  --region ap-southeast-4
```

### ALB health check failing
```bash
# Check target health
TG_ARN=$(aws elbv2 describe-target-groups --names resume-api-tg --query 'TargetGroups[0].TargetGroupArn' --output text --region ap-southeast-4)
aws elbv2 describe-target-health --target-group-arn ${TG_ARN} --region ap-southeast-4

# Test health endpoint directly
curl http://$(aws elbv2 describe-load-balancers --names resume-api-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-southeast-4)/health
```

## 💰 Cost Monitoring

```bash
# Get current month costs (requires Cost Explorer API)
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1
```

## 📚 Documentation

- [Day 4 Deployment Guide](DAY4-DEPLOYMENT.md)
- [ECS Deployment Details](infra/README-ECS.md)
- [IAM Setup for ECS](infra/IAM-SETUP-ECS.md)
- [Day 4 Summary](SUMMARY-DAY4.md)
- [Security Checklist](SECURITY-CHECKLIST.md)
