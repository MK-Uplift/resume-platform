# IAM Permissions for ECS Deployment

## Required AWS Managed Policies

Your IAM user (`MK-Uplift-11`) needs the following managed policies:

### Already Added (from Day 3):
- ✅ `AmazonEC2FullAccess` - For VPC, Security Groups
- ✅ `AmazonRDSFullAccess` - For RDS database
- ✅ `AmazonS3FullAccess` - For S3 bucket
- ✅ `CloudFrontFullAccess` - For CloudFront distribution

### New for Day 4:
- ⬜ `AmazonECS_FullAccess` - For ECS clusters, services, tasks
- ⬜ `AmazonEC2ContainerRegistryFullAccess` - For ECR repositories
- ⬜ `IAMFullAccess` - For creating ECS task execution roles
- ⬜ `CloudWatchLogsFullAccess` - For CloudWatch log groups
- ⬜ `ElasticLoadBalancingFullAccess` - For Application Load Balancer
- ⬜ `SecretsManagerReadWrite` - For AWS Secrets Manager

## How to Add Policies (AWS Console)

1. Go to IAM Console: https://console.aws.amazon.com/iam/
2. Click "Users" in the left sidebar
3. Click on your user: `MK-Uplift-11`
4. Click "Add permissions" → "Attach policies directly"
5. Search and select each policy:
   - `AmazonECS_FullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `IAMFullAccess`
   - `CloudWatchLogsFullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `SecretsManagerReadWrite`
6. Click "Next" → "Add permissions"

## Alternative: Custom Policy (Least Privilege)

If you prefer a more restrictive policy, use this custom policy instead:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECSFullAccess",
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ecr:*",
        "logs:*",
        "elasticloadbalancing:*",
        "secretsmanager:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPassRole",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "*"
    }
  ]
}
```

## Verify Permissions

After adding policies, verify with:

```bash
# Test ECS access
aws ecs list-clusters --region ap-southeast-4

# Test ECR access
aws ecr describe-repositories --region ap-southeast-4

# Test ALB access
aws elbv2 describe-load-balancers --region ap-southeast-4

# Test Secrets Manager access
aws secretsmanager list-secrets --region ap-southeast-4
```

## Common Permission Errors

### Error: "User is not authorized to perform: ecs:CreateCluster"
**Solution**: Add `AmazonECS_FullAccess` policy

### Error: "User is not authorized to perform: ecr:CreateRepository"
**Solution**: Add `AmazonEC2ContainerRegistryFullAccess` policy

### Error: "User is not authorized to perform: iam:PassRole"
**Solution**: Add `IAMFullAccess` policy or the custom policy above

### Error: "User is not authorized to perform: logs:CreateLogGroup"
**Solution**: Add `CloudWatchLogsFullAccess` policy

### Error: "User is not authorized to perform: elasticloadbalancing:CreateLoadBalancer"
**Solution**: Add `ElasticLoadBalancingFullAccess` policy

## Security Best Practices

1. **Use IAM Roles for ECS Tasks**: Don't hardcode credentials in containers
2. **Least Privilege**: Only grant necessary permissions
3. **Secrets Manager**: Store sensitive data (connection strings, API keys)
4. **CloudWatch Logs**: Enable logging for audit trails
5. **ECR Image Scanning**: Enable vulnerability scanning

## Cost Considerations

Most IAM operations are free, but be aware of:
- **Secrets Manager**: $0.40/secret/month + $0.05 per 10,000 API calls
- **CloudWatch Logs**: $0.50/GB ingested (after free tier)
- **ECR**: $0.10/GB/month storage (after 500 MB free tier)

## Next Steps

After adding permissions:
1. Run `terraform plan` to verify access
2. Run `terraform apply` to create resources
3. Use `./deploy-day4.sh` for automated deployment
