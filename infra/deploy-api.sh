#!/bin/bash

set -e

echo "🚀 Deploying API to ECS..."

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="ap-southeast-4"
ECR_REPOSITORY="resume-api"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "📦 Building Docker image..."
cd ../Resume.Api
docker build -t ${ECR_URI}:latest .

echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "⬆️  Pushing image to ECR..."
docker push ${ECR_URI}:latest

echo "🔄 Updating ECS service..."
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --force-new-deployment \
  --region ${AWS_REGION}

echo "⏳ Waiting for service to stabilize..."
aws ecs wait services-stable \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ${AWS_REGION}

echo "✅ Deployment complete!"

# Get ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers --names resume-api-alb --query 'LoadBalancers[0].DNSName' --output text --region ${AWS_REGION})
echo ""
echo "🌐 API URL: http://${ALB_DNS}"
echo "🏥 Health check: http://${ALB_DNS}/health"
