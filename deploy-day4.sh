#!/bin/bash

set -e

echo "🚀 Day 4: Deploying API to ECS Fargate"
echo "========================================"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI configured"
echo ""

# Step 1: Apply Terraform
echo "📦 Step 1: Applying Terraform configuration..."
cd infra

if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

echo "Planning infrastructure changes..."
terraform plan -out=tfplan

read -p "Apply these changes? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

terraform apply tfplan
rm tfplan

echo ""
echo "✅ Infrastructure created"
echo ""

# Get outputs
ECR_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS=$(terraform output -raw alb_dns_name)
API_URL=$(terraform output -raw api_url)

echo "📋 Infrastructure Details:"
echo "  ECR Repository: ${ECR_URL}"
echo "  ALB DNS: ${ALB_DNS}"
echo "  API URL: ${API_URL}"
echo ""

# Step 2: Build and push Docker image
echo "🐳 Step 2: Building and pushing Docker image..."
cd ..

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="ap-southeast-4"

echo "Building Docker image..."
cd Resume.Api
docker build -t ${ECR_URL}:latest .

echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Pushing image to ECR..."
docker push ${ECR_URL}:latest

echo ""
echo "✅ Docker image pushed to ECR"
echo ""

# Step 3: Update ECS service
echo "🔄 Step 3: Updating ECS service..."
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --force-new-deployment \
  --region ${AWS_REGION} \
  --no-cli-pager

echo "Waiting for service to stabilize (this may take 2-3 minutes)..."
aws ecs wait services-stable \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ${AWS_REGION}

echo ""
echo "✅ ECS service updated and stable"
echo ""

# Step 4: Test API
echo "🧪 Step 4: Testing API..."
sleep 10  # Give ALB a moment to register targets

echo "Testing health endpoint..."
if curl -f -s "${API_URL}/health" > /dev/null; then
    echo "✅ Health check passed"
else
    echo "⚠️  Health check failed (may need a few more seconds)"
fi

echo ""
echo "Testing messages endpoint..."
if curl -f -s "${API_URL}/api/messages" > /dev/null; then
    echo "✅ Messages endpoint working"
else
    echo "⚠️  Messages endpoint not ready yet"
fi

echo ""
echo "=========================================="
echo "🎉 Day 4 Deployment Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Test API manually:"
echo "   curl ${API_URL}/health"
echo "   curl ${API_URL}/api/messages"
echo ""
echo "2. Update frontend config:"
echo "   Edit Resume.Web/wwwroot/appsettings.Production.json"
echo "   Replace API_URL_PLACEHOLDER with: ${API_URL}"
echo ""
echo "3. Deploy frontend:"
echo "   git add ."
echo "   git commit -m \"Day 4: Add API containerization and ECS deployment\""
echo "   git push origin main"
echo ""
echo "4. Monitor logs:"
echo "   aws logs tail /ecs/resume-api --follow --region ap-southeast-4"
echo ""
echo "🌐 Your API is live at: ${API_URL}"
echo ""
