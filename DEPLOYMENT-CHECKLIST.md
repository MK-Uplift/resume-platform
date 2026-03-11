# Day 4 Deployment Checklist

## ✅ Pre-Deployment Checklist

### 1. AWS Credentials
- [ ] AWS CLI configured (`aws configure`)
- [ ] Correct AWS region set (`ap-southeast-4`)
- [ ] IAM user has required permissions (see `infra/IAM-SETUP-ECS.md`)

### 2. Required Tools
- [ ] Terraform installed (`terraform --version`)
- [ ] Docker installed (`docker --version`)
- [ ] .NET 8 SDK installed (`dotnet --version`)
- [ ] AWS CLI installed (`aws --version`)

### 3. IAM Permissions
- [ ] AmazonEC2FullAccess
- [ ] AmazonRDSFullAccess
- [ ] AmazonS3FullAccess
- [ ] CloudFrontFullAccess
- [ ] AmazonECS_FullAccess
- [ ] AmazonEC2ContainerRegistryFullAccess
- [ ] IAMFullAccess
- [ ] CloudWatchLogsFullAccess
- [ ] ElasticLoadBalancingFullAccess
- [ ] SecretsManagerReadWrite

### 4. Existing Resources (from Day 1-3)
- [ ] S3 bucket exists: `mk-uplift-resume-web`
- [ ] CloudFront distribution exists
- [ ] RDS instance exists: `resume-db`
- [ ] Secrets Manager secret exists: `resume-rds-credentials`

## 🚀 Deployment Steps

### Step 1: Review Code Changes
```bash
# Check what files changed
git status

# Review changes
git diff
```

- [ ] Dockerfile created
- [ ] ECS Terraform files created
- [ ] Frontend form added
- [ ] GitHub Actions updated

### Step 2: Test Docker Build Locally (Optional)
```bash
cd Resume.Api
docker build -t resume-api:local .
```

- [ ] Docker build succeeds
- [ ] No build errors

### Step 3: Deploy Infrastructure
```bash
cd infra

# Initialize Terraform (if needed)
terraform init

# Review changes
terraform plan

# Apply changes
terraform apply
```

- [ ] Terraform plan shows expected resources
- [ ] ECR repository created
- [ ] ECS cluster created
- [ ] ECS service created
- [ ] ALB created
- [ ] Security groups configured
- [ ] IAM roles created
- [ ] CloudWatch log group created

### Step 4: Get Infrastructure Outputs
```bash
terraform output ecr_repository_url
terraform output alb_dns_name
terraform output api_url
```

- [ ] ECR URL obtained
- [ ] ALB DNS obtained
- [ ] API URL obtained

### Step 5: Build and Push Docker Image
```bash
# Option 1: Use deployment script
./deploy-api.sh

# Option 2: Manual deployment
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="ap-southeast-4"

cd ../Resume.Api
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/resume-api:latest .

aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/resume-api:latest
```

- [ ] Docker image built successfully
- [ ] Logged in to ECR
- [ ] Image pushed to ECR

### Step 6: Deploy to ECS
```bash
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --force-new-deployment \
  --region ap-southeast-4

aws ecs wait services-stable \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ap-southeast-4
```

- [ ] ECS service updated
- [ ] Service stabilized (may take 2-3 minutes)

### Step 7: Verify API Deployment
```bash
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names resume-api-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-southeast-4)

# Test health endpoint
curl http://${ALB_DNS}/health

# Test messages endpoint
curl http://${ALB_DNS}/api/messages
```

- [ ] Health check returns `{"status":"ok"}`
- [ ] Messages endpoint returns `[]` or existing messages
- [ ] No errors in response

### Step 8: Check Logs
```bash
aws logs tail /ecs/resume-api --follow --region ap-southeast-4
```

- [ ] Container started successfully
- [ ] No error messages
- [ ] Database connection successful

### Step 9: Update Frontend Configuration
```bash
# Get ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names resume-api-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-southeast-4)

# Update Resume.Web/wwwroot/appsettings.Production.json
# Replace API_URL_PLACEHOLDER with http://${ALB_DNS}
```

- [ ] Production config updated with ALB URL

### Step 10: Commit and Push
```bash
git add .
git commit -m "Day 4: Add API containerization and ECS deployment"
git push origin main
```

- [ ] All files committed
- [ ] Pushed to GitHub
- [ ] GitHub Actions triggered

### Step 11: Monitor GitHub Actions
```bash
# Watch GitHub Actions (if gh CLI installed)
gh run watch

# Or check on GitHub
# https://github.com/YOUR_USERNAME/YOUR_REPO/actions
```

- [ ] Frontend deployment succeeded
- [ ] API deployment succeeded
- [ ] No errors in workflow

### Step 12: Test Complete Flow
1. Visit frontend: `https://ddcfte7n5r9tt.cloudfront.net`
2. Scroll to Contact section
3. Fill out form:
   - Name: Test User
   - Email: test@example.com
   - Message: Testing Day 4 deployment
4. Submit form

- [ ] Form submits successfully
- [ ] Success message displayed
- [ ] No CORS errors in browser console

### Step 13: Verify Data in Database
```bash
# Check API logs for INSERT statement
aws logs tail /ecs/resume-api --since 5m --region ap-southeast-4

# Or query API
curl http://${ALB_DNS}/api/messages
```

- [ ] Message appears in API response
- [ ] Data saved to database

## 🧪 Post-Deployment Verification

### API Health
```bash
ALB_DNS=$(aws elbv2 describe-load-balancers --names resume-api-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-southeast-4)

# Health check
curl -v http://${ALB_DNS}/health

# Should return: {"status":"ok"}
```

- [ ] Returns 200 OK
- [ ] Response is valid JSON

### ALB Target Health
```bash
TG_ARN=$(aws elbv2 describe-target-groups \
  --names resume-api-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region ap-southeast-4)

aws elbv2 describe-target-health \
  --target-group-arn ${TG_ARN} \
  --region ap-southeast-4
```

- [ ] Target state is "healthy"
- [ ] No unhealthy targets

### ECS Service Status
```bash
aws ecs describe-services \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ap-southeast-4 \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

- [ ] Status is "ACTIVE"
- [ ] Running count equals desired count (1)

### CloudWatch Logs
```bash
aws logs tail /ecs/resume-api --since 10m --region ap-southeast-4
```

- [ ] Logs are being generated
- [ ] No error messages
- [ ] Application started successfully

### Frontend-Backend Integration
1. Open browser to: `https://ddcfte7n5r9tt.cloudfront.net`
2. Open browser DevTools (F12)
3. Go to Network tab
4. Submit contact form
5. Check network requests

- [ ] POST request to API succeeds (200 OK)
- [ ] No CORS errors
- [ ] Response is valid JSON

## 📊 Resource Verification

### Terraform State
```bash
cd infra
terraform state list
```

Expected resources:
- [ ] aws_ecr_repository.api
- [ ] aws_ecs_cluster.main
- [ ] aws_ecs_service.api
- [ ] aws_ecs_task_definition.api
- [ ] aws_lb.api
- [ ] aws_lb_target_group.api
- [ ] aws_lb_listener.api
- [ ] aws_security_group.alb
- [ ] aws_security_group.ecs_tasks
- [ ] aws_cloudwatch_log_group.api
- [ ] aws_iam_role.ecs_task_execution
- [ ] aws_iam_role.ecs_task

### AWS Console Verification
1. **ECR**: https://console.aws.amazon.com/ecr/
   - [ ] Repository `resume-api` exists
   - [ ] Latest image is present

2. **ECS**: https://console.aws.amazon.com/ecs/
   - [ ] Cluster `resume-cluster` exists
   - [ ] Service `resume-api-service` is running
   - [ ] 1 task is running

3. **EC2 Load Balancers**: https://console.aws.amazon.com/ec2/
   - [ ] ALB `resume-api-alb` exists
   - [ ] Target group has healthy targets

4. **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch/
   - [ ] Log group `/ecs/resume-api` exists
   - [ ] Recent log streams present

## 🐛 Troubleshooting

If any step fails, see:
- [Quick Reference](QUICK-REFERENCE.md) - Common commands
- [ECS Deployment Guide](infra/README-ECS.md) - Detailed troubleshooting
- [Day 4 Deployment Guide](DAY4-DEPLOYMENT.md) - Step-by-step instructions

Common issues:
- **Container won't start**: Check CloudWatch logs
- **Database connection failed**: Verify security groups and connection string
- **ALB health check failing**: Verify `/health` endpoint and port 8080
- **CORS errors**: Update API CORS configuration with CloudFront URL

## 💰 Cost Check

After deployment, monitor costs:
```bash
# Check current month costs (requires Cost Explorer API)
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1
```

Expected monthly cost: ~$26.40 (after free tier)

## ✅ Deployment Complete!

If all checkboxes are checked, congratulations! 🎉

Your Day 4 deployment is complete:
- ✅ API containerized with Docker
- ✅ Deployed to ECS Fargate
- ✅ Accessible via Application Load Balancer
- ✅ Frontend integrated with backend
- ✅ CI/CD pipeline automated
- ✅ Complete cloud-native architecture

## 📝 Next Steps

1. Monitor application for 24 hours
2. Review CloudWatch logs for any issues
3. Test under load (optional)
4. Plan Day 5 enhancements:
   - HTTPS with ACM
   - Custom domain
   - Auto-scaling
   - Monitoring alerts

---

**Deployment Date**: _____________  
**Deployed By**: _____________  
**Notes**: _____________
