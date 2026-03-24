#!/bin/bash
# 恢复所有资源
set -e

REGION="ap-southeast-4"
CLUSTER="resume-cluster"
SERVICE="resume-api-service"
RDS_INSTANCE="resume-db"

echo "▶️  启动开发环境..."

# 1. 启动 RDS
echo "启动 RDS（需要几分钟）..."
aws rds start-db-instance \
  --db-instance-identifier $RDS_INSTANCE \
  --region $REGION > /dev/null

# 等 RDS available
echo "等待 RDS 就绪..."
aws rds wait db-instance-available \
  --db-instance-identifier $RDS_INSTANCE \
  --region $REGION
echo "✅ RDS ready"

# 2. ECS service 恢复到 1
echo "启动 ECS service..."
aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --desired-count 1 \
  --region $REGION > /dev/null
echo "✅ ECS starting"

echo ""
echo "🚀 环境已恢复"
echo "   等约 2 分钟 ECS task 健康检查通过后 API 可用"
echo "   API: https://d60tbbl9t8f4g.cloudfront.net/health"
