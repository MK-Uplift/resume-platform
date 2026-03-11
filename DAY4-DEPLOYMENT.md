# Day 4: API 容器化和 ECS 部署

## 目标
✅ API 容器化（Dockerfile）  
✅ 推镜像到 ECR  
✅ 部署 API 到 ECS Fargate  
✅ 设置 ALB 公网访问  
✅ 前端调用 API（完整闭环）

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────┬────────────────────────────────┬───────────────┘
             │                                 │
             │ HTTPS                           │ HTTP
             ▼                                 ▼
    ┌────────────────┐              ┌──────────────────┐
    │   CloudFront   │              │       ALB        │
    │  (Frontend)    │              │   (API Gateway)  │
    └────────┬───────┘              └────────┬─────────┘
             │                                │
             │                                │
             ▼                                ▼
    ┌────────────────┐              ┌──────────────────┐
    │   S3 Bucket    │              │  ECS Fargate     │
    │  Blazor WASM   │              │  (resume-api)    │
    └────────────────┘              └────────┬─────────┘
                                              │
                                              │ Port 5432
                                              ▼
                                    ┌──────────────────┐
                                    │  RDS PostgreSQL  │
                                    │   (resume-db)    │
                                    └──────────────────┘
```

## 步骤 1: 本地测试 Dockerfile

```bash
cd Resume.Api

# 构建 Docker 镜像
docker build -t resume-api:local .

# 测试运行（需要替换连接字符串）
docker run -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="Host=resume-db.cpqckaaqa750.ap-southeast-4.rds.amazonaws.com;Port=5432;Database=resume;Username=postgres;Password=YOUR_PASSWORD" \
  resume-api:local

# 测试健康检查
curl http://localhost:8080/health
```

## 步骤 2: 部署基础设施（Terraform）

```bash
cd infra

# 查看将要创建的资源
terraform plan

# 应用配置（创建 ECR, ECS, ALB）
terraform apply

# 获取重要输出
terraform output ecr_repository_url
terraform output alb_dns_name
terraform output api_url
```

创建的资源：
- **ECR Repository**: `resume-api`
- **ECS Cluster**: `resume-cluster`
- **ECS Service**: `resume-api-service`
- **ALB**: `resume-api-alb`
- **Security Groups**: ALB SG, ECS Tasks SG
- **IAM Roles**: Task execution role, Task role
- **CloudWatch Log Group**: `/ecs/resume-api`

## 步骤 3: 构建和推送 Docker 镜像

### 方法 1: 使用部署脚本（推荐）

```bash
cd infra
./deploy-api.sh
```

### 方法 2: 手动部署

```bash
# 获取 AWS 账户 ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="ap-southeast-4"

# 登录 ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# 构建镜像
cd Resume.Api
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/resume-api:latest .

# 推送到 ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/resume-api:latest

# 更新 ECS 服务
aws ecs update-service \
  --cluster resume-cluster \
  --service resume-api-service \
  --force-new-deployment \
  --region ${AWS_REGION}

# 等待部署完成
aws ecs wait services-stable \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ${AWS_REGION}
```

## 步骤 4: 验证 API 部署

```bash
# 获取 ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names resume-api-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-southeast-4)

echo "API URL: http://${ALB_DNS}"

# 测试健康检查
curl http://${ALB_DNS}/health

# 测试 GET 接口
curl http://${ALB_DNS}/api/messages

# 测试 POST 接口
curl -X POST http://${ALB_DNS}/api/messages \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","message":"Hello from CLI!"}'
```

## 步骤 5: 更新前端配置

前端已经配置好了 API 调用，但需要更新生产环境的 API URL：

```bash
# 获取 ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names resume-api-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-southeast-4)

# 手动更新 Resume.Web/wwwroot/appsettings.Production.json
# 将 API_URL_PLACEHOLDER 替换为 http://${ALB_DNS}
```

或者让 GitHub Actions 自动处理（已配置）。

## 步骤 6: 部署前端

```bash
# 本地测试
cd Resume.Web
dotnet run

# 或者推送到 GitHub，让 CI/CD 自动部署
git add .
git commit -m "Day 4: Add API containerization and ECS deployment"
git push origin main
```

GitHub Actions 会自动：
1. 构建前端并部署到 S3/CloudFront
2. 构建 API Docker 镜像并推送到 ECR
3. 更新 ECS 服务
4. 替换前端配置中的 API URL

## 步骤 7: 测试完整闭环

1. 访问前端：`https://ddcfte7n5r9tt.cloudfront.net`
2. 滚动到 Contact 部分
3. 填写表单并提交
4. 应该看到成功消息
5. 刷新页面，消息应该保存在数据库中

## 监控和调试

### 查看 ECS 日志
```bash
# 实时查看日志
aws logs tail /ecs/resume-api --follow --region ap-southeast-4

# 查看最近的错误
aws logs tail /ecs/resume-api --since 1h --filter-pattern "ERROR" --region ap-southeast-4
```

### 查看 ECS 服务状态
```bash
aws ecs describe-services \
  --cluster resume-cluster \
  --services resume-api-service \
  --region ap-southeast-4
```

### 查看运行中的任务
```bash
aws ecs list-tasks \
  --cluster resume-cluster \
  --service-name resume-api-service \
  --region ap-southeast-4
```

### 查看 ALB 目标健康状态
```bash
# 获取目标组 ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --names resume-api-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region ap-southeast-4)

# 查看目标健康状态
aws elbv2 describe-target-health \
  --target-group-arn ${TG_ARN} \
  --region ap-southeast-4
```

## 常见问题

### 1. 容器启动失败
- 检查 CloudWatch 日志：`/ecs/resume-api`
- 验证 Secrets Manager 中的连接字符串
- 确认 IAM 角色有 Secrets Manager 权限

### 2. 无法连接数据库
- 检查 RDS 安全组是否允许 ECS Tasks SG
- 验证连接字符串格式
- 确认 RDS 和 ECS 在同一个 VPC

### 3. ALB 健康检查失败
- 确认容器监听 8080 端口
- 验证 `/health` 端点返回 200
- 检查 ECS Tasks SG 允许 ALB 流量

### 4. CORS 错误
- 确认 API 的 CORS 配置包含 CloudFront URL
- 检查 ALB 是否正确转发请求

## 成本估算

- **ECS Fargate**: ~$10/月（1 任务，0.25 vCPU，512 MB）
- **ALB**: ~$16/月
- **RDS**: 免费套餐（db.t3.micro）
- **ECR**: 免费套餐（500 MB）
- **CloudWatch Logs**: 免费套餐（5 GB）

**总计**: ~$26/月（免费套餐过期后）

## 下一步优化

1. **HTTPS**: 配置 ACM 证书和 HTTPS 监听器
2. **自定义域名**: Route53 + ACM
3. **Auto-scaling**: ECS 服务自动扩展
4. **监控告警**: CloudWatch Alarms
5. **性能优化**: CloudFront 缓存策略
6. **安全加固**: WAF, Security Hub

## 文件清单

新增文件：
- `Resume.Api/Dockerfile` - Docker 镜像定义
- `Resume.Api/.dockerignore` - Docker 构建排除文件
- `Resume.Api/build-docker.sh` - 本地构建脚本
- `infra/ecr.tf` - ECR 仓库配置
- `infra/ecs.tf` - ECS 集群和服务配置
- `infra/alb.tf` - ALB 配置
- `infra/deploy-api.sh` - 部署脚本
- `infra/README-ECS.md` - ECS 部署文档
- `Resume.Web/wwwroot/appsettings.json` - 开发环境配置
- `Resume.Web/wwwroot/appsettings.Production.json` - 生产环境配置

修改文件：
- `infra/rds.tf` - 添加 ECS Tasks 访问权限
- `.github/workflows/deploy.yml` - 添加 API 部署流程
- `Resume.Web/Pages/Index.razor` - 添加联系表单
- `Resume.Web/Program.cs` - 配置 API BaseURL
- `Resume.Web/wwwroot/css/app.css` - 添加表单样式
- `Resume.Web/_Imports.razor` - 添加必要的 using 语句

## 完成标志

✅ Dockerfile 创建并测试  
✅ ECR 仓库创建  
✅ ECS Fargate 集群和服务运行  
✅ ALB 配置并可公网访问  
✅ API 健康检查通过  
✅ 前端表单可以提交数据  
✅ 数据成功保存到 RDS  
✅ GitHub Actions CI/CD 配置完成  

🎉 Day 4 完成！API 已容器化并部署到 ECS Fargate，前端可以通过 ALB 访问 API，完整闭环实现！
