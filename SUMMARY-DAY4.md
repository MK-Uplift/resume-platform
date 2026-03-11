# Day 4 总结：API 容器化和 ECS Fargate 部署

## 🎯 完成的目标

✅ **API 容器化**
- 创建 Dockerfile（多阶段构建）
- 配置 .dockerignore
- 本地测试脚本

✅ **ECR 镜像仓库**
- Terraform 配置 ECR repository
- 生命周期策略（保留最近 5 个镜像）
- 镜像扫描启用

✅ **ECS Fargate 部署**
- ECS Cluster: `resume-cluster`
- ECS Service: `resume-api-service`
- Task Definition: 256 CPU, 512 MB 内存
- CloudWatch Logs: `/ecs/resume-api`
- Secrets Manager 集成（数据库连接字符串）

✅ **Application Load Balancer**
- 公网访问的 ALB
- 健康检查配置（`/health` 端点）
- Target Group 配置
- Security Groups 配置

✅ **前端 API 集成**
- 联系表单组件
- HttpClient 配置
- 环境配置（开发/生产）
- 表单验证和错误处理

✅ **CI/CD 自动化**
- GitHub Actions 构建 Docker 镜像
- 推送到 ECR
- 自动部署到 ECS
- 前端配置自动更新

## 📁 新增文件

### Docker 相关
- `Resume.Api/Dockerfile` - Docker 镜像定义
- `Resume.Api/.dockerignore` - 构建排除文件
- `Resume.Api/build-docker.sh` - 本地构建脚本

### Terraform 配置
- `infra/ecr.tf` - ECR 仓库配置
- `infra/ecs.tf` - ECS 集群、服务、任务定义
- `infra/alb.tf` - Application Load Balancer 配置

### 部署脚本
- `infra/deploy-api.sh` - API 部署脚本
- `deploy-day4.sh` - 完整部署流程脚本

### 文档
- `infra/README-ECS.md` - ECS 部署详细文档
- `infra/IAM-SETUP-ECS.md` - IAM 权限配置指南
- `DAY4-DEPLOYMENT.md` - Day 4 部署指南
- `SUMMARY-DAY4.md` - 本文档

### 前端配置
- `Resume.Web/wwwroot/appsettings.json` - 开发环境配置
- `Resume.Web/wwwroot/appsettings.Production.json` - 生产环境配置

## 🔧 修改的文件

- `infra/rds.tf` - 添加 ECS Tasks 安全组访问
- `.github/workflows/deploy.yml` - 添加 API 部署流程
- `Resume.Web/Pages/Index.razor` - 添加联系表单
- `Resume.Web/Program.cs` - 配置 API BaseURL
- `Resume.Web/wwwroot/css/app.css` - 表单样式
- `Resume.Web/_Imports.razor` - 添加必要的 using 语句
- `.gitignore` - 添加 Docker 和 Terraform 相关忽略

## 🏗️ 架构变化

### Day 3 架构
```
CloudFront → S3 (Frontend)
Local API → RDS
```

### Day 4 架构
```
CloudFront → S3 (Frontend)
     ↓ (API calls)
    ALB → ECS Fargate (API Container) → RDS
```

## 📊 资源清单

| 资源类型 | 名称 | 用途 |
|---------|------|------|
| ECR Repository | `resume-api` | Docker 镜像存储 |
| ECS Cluster | `resume-cluster` | 容器编排 |
| ECS Service | `resume-api-service` | 运行 API 容器 |
| ECS Task | `resume-api` | 容器定义 |
| ALB | `resume-api-alb` | 负载均衡器 |
| Target Group | `resume-api-tg` | ALB 目标组 |
| Security Group | `resume-alb-sg` | ALB 安全组 |
| Security Group | `resume-ecs-tasks-sg` | ECS 任务安全组 |
| IAM Role | `resume-ecs-task-execution-role` | 任务执行角色 |
| IAM Role | `resume-ecs-task-role` | 任务角色 |
| CloudWatch Log Group | `/ecs/resume-api` | 日志存储 |

## 🔐 安全配置

✅ **Secrets Manager**
- 数据库连接字符串存储在 AWS Secrets Manager
- ECS 任务通过环境变量注入

✅ **IAM 角色**
- Task Execution Role: 拉取镜像、读取 Secrets、写日志
- Task Role: 应用程序运行时权限

✅ **Security Groups**
- ALB: 允许公网 HTTP/HTTPS
- ECS Tasks: 只允许 ALB 流量
- RDS: 允许 ECS Tasks 和本地 IP

✅ **网络隔离**
- ECS 任务运行在私有子网（使用 NAT Gateway）
- ALB 在公网子网
- RDS 在私有子网

## 💰 成本估算

| 服务 | 配置 | 月成本（USD） |
|------|------|--------------|
| ECS Fargate | 1 task, 0.25 vCPU, 512 MB | ~$10 |
| ALB | 基础费用 + 数据传输 | ~$16 |
| RDS | db.t3.micro, 20GB | 免费套餐 |
| ECR | 500 MB 存储 | 免费套餐 |
| CloudWatch Logs | 5 GB/月 | 免费套餐 |
| Secrets Manager | 1 secret | $0.40 |
| **总计** | | **~$26.40/月** |

## 🚀 部署流程

### 方法 1: 自动化脚本（推荐）
```bash
./deploy-day4.sh
```

### 方法 2: 手动步骤
```bash
# 1. 部署基础设施
cd infra
terraform apply

# 2. 构建和推送镜像
cd ../Resume.Api
docker build -t <ECR_URL>:latest .
docker push <ECR_URL>:latest

# 3. 更新 ECS 服务
aws ecs update-service --cluster resume-cluster --service resume-api-service --force-new-deployment

# 4. 部署前端
git push origin main  # GitHub Actions 自动部署
```

## 🧪 测试验证

### API 测试
```bash
# 获取 ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers --names resume-api-alb --query 'LoadBalancers[0].DNSName' --output text)

# 健康检查
curl http://${ALB_DNS}/health

# 获取消息
curl http://${ALB_DNS}/api/messages

# 发送消息
curl -X POST http://${ALB_DNS}/api/messages \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","message":"Hello!"}'
```

### 前端测试
1. 访问 `https://ddcfte7n5r9tt.cloudfront.net`
2. 滚动到 Contact 部分
3. 填写并提交表单
4. 验证成功消息

## 📈 监控和日志

### CloudWatch Logs
```bash
# 实时查看日志
aws logs tail /ecs/resume-api --follow

# 查看错误
aws logs tail /ecs/resume-api --since 1h --filter-pattern "ERROR"
```

### ECS 服务状态
```bash
aws ecs describe-services --cluster resume-cluster --services resume-api-service
```

### ALB 健康检查
```bash
TG_ARN=$(aws elbv2 describe-target-groups --names resume-api-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn ${TG_ARN}
```

## 🐛 常见问题

### 容器启动失败
- 检查 CloudWatch Logs
- 验证 Secrets Manager 连接字符串
- 确认 IAM 角色权限

### 数据库连接失败
- 检查 RDS 安全组
- 验证连接字符串格式
- 确认 VPC 配置

### ALB 健康检查失败
- 确认容器监听 8080 端口
- 验证 `/health` 端点
- 检查安全组配置

### CORS 错误
- 更新 API CORS 配置
- 添加 CloudFront URL 到允许列表

## 🎓 学到的技能

1. **Docker 容器化**
   - 多阶段构建
   - 镜像优化
   - .dockerignore 配置

2. **AWS ECS Fargate**
   - Serverless 容器运行
   - Task Definition 配置
   - Service 管理

3. **AWS ECR**
   - 镜像仓库管理
   - 生命周期策略
   - 镜像扫描

4. **Application Load Balancer**
   - 负载均衡配置
   - 健康检查
   - Target Group 管理

5. **AWS Secrets Manager**
   - 敏感信息管理
   - ECS 集成
   - 环境变量注入

6. **CI/CD 自动化**
   - GitHub Actions
   - Docker 构建和推送
   - ECS 自动部署

## 📝 下一步（Day 5+）

可能的优化方向：

1. **HTTPS 配置**
   - ACM 证书
   - HTTPS 监听器
   - HTTP → HTTPS 重定向

2. **自定义域名**
   - Route53 配置
   - 域名解析
   - SSL 证书

3. **Auto-scaling**
   - ECS Service Auto Scaling
   - Target Tracking
   - 成本优化

4. **监控告警**
   - CloudWatch Alarms
   - SNS 通知
   - 错误率监控

5. **性能优化**
   - CloudFront 缓存
   - API 响应优化
   - 数据库查询优化

6. **安全加固**
   - AWS WAF
   - Security Hub
   - GuardDuty

## 🎉 总结

Day 4 成功将 API 容器化并部署到 ECS Fargate，实现了：
- ✅ Serverless 容器运行（无需管理服务器）
- ✅ 自动扩展能力（可配置）
- ✅ 高可用性（ALB + 多 AZ）
- ✅ 安全的密钥管理（Secrets Manager）
- ✅ 完整的日志记录（CloudWatch）
- ✅ CI/CD 自动化（GitHub Actions）
- ✅ 前后端完整闭环

整个平台现在是一个生产就绪的云原生应用！🚀
