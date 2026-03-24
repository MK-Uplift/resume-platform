#!/bin/bash
# 停止所有按小时计费的资源（不删除，保留配置）
set -e

REGION="ap-southeast-4"
CLUSTER="resume-cluster"
SERVICE="resume-api-service"
RDS_INSTANCE="resume-db"

echo "⏹️  停止开发环境..."

# 1. ECS service 缩到 0
echo "停止 ECS service..."
aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --desired-count 0 \
  --region $REGION > /dev/null
echo "✅ ECS stopped"

# 2. 停止 RDS（最贵的）
echo "停止 RDS..."
aws rds stop-db-instance \
  --db-instance-identifier $RDS_INSTANCE \
  --region $REGION > /dev/null
echo "✅ RDS stopping (需要几分钟)"

echo ""
echo "💰 节省中: ECS + RDS 已停止"
echo "   ALB 仍在运行（停不了，但没流量费用很低）"
echo "   CloudFront 仍在运行（按请求计费，几乎免费）"
echo "   恢复运行: ./scripts/start-dev.sh"
