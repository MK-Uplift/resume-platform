# Day 5 完整总结

## 总体目标
解决混合内容（HTTPS/HTTP）问题，完善监控告警，优化 CI/CD pipeline，添加邮件通知，重新设计前端 UI。

---

## 一、修复 ECS Task 无法启动问题

### 问题
ECS service 显示 `Running: 0, Pending: 0, Desired: 1`，task 反复启动后被停掉，ALB 返回 503。

### 根本原因
`mcr.microsoft.com/dotnet/aspnet:8.0` 是 Debian slim 精简镜像，**默认不包含 `curl` 或 `wget`**。
ECS 容器 health check 命令是 `curl -f http://localhost:8080/health || exit 1`，每次执行都失败（命令不存在），ECS 判定容器 UNHEALTHY，3 次重试后停掉 task。

### 诊断过程
- `aws ecs describe-services` 查看 running/pending count
- `aws ecs describe-tasks` 查看 stopCode 和 stoppedReason → `Task failed container health checks`
- `aws logs get-log-events` 查看 CloudWatch 日志 → app 启动正常，但完全没有 health check 执行的输出
- 确认 exit code 为 0（app 没崩），排除应用层问题
- 结论：health check 命令本身无法执行

### 修复
1. `Resume.Api/Dockerfile` 加入 curl 安装：
   ```dockerfile
   RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
   ```
2. 手动注册 task definition revision 7（curl 版本），立即恢复服务
3. Pipeline 加入强制覆盖 health check 的步骤，防止以后 pipeline 继承错误配置

### 教训
- ECS 容器 health check 的执行结果不写入 CloudWatch，只能通过 `describe-tasks` 查看
- 精简镜像（slim/alpine）不包含常用工具，health check 要么装工具，要么用应用层 HTTP 检查

---

## 二、修复 CI/CD Pipeline 问题

### 问题 1：wait-for-service-stability 超时
`aws ecs wait services-stable` 等待超过 20 分钟报错：
```
Waiter ServicesStable failed: Max attempts exceeded
```

### 修复
将 `amazon-ecs-deploy-task-definition` action 的 `wait-for-service-stability` 改为 `false`，不等待稳定性。

### 问题 2：task definition 写死 revision 1
Pipeline 每次都从 `resume-api:1` 渲染新 task definition，导致 health check 等配置永远继承旧版本。

### 修复
动态获取当前 service 使用的 task definition：
```yaml
- name: Get latest task definition
  run: |
    TASK_DEF_ARN=$(aws ecs describe-services \
      --cluster ${{ env.ECS_CLUSTER }} \
      --services ${{ env.ECS_SERVICE }} \
      --query 'services[0].taskDefinition' \
      --output text)
    echo "arn=$TASK_DEF_ARN" >> $GITHUB_OUTPUT
```

### 问题 3：deploy-web job 的 sed 替换破坏 appsettings
Pipeline 里有一段 `sed -i 's|API_URL_PLACEHOLDER|...|g'` 试图替换 API URL，但 `appsettings.Production.json` 已经是硬编码的 CloudFront HTTPS URL，sed 找不到占位符但也不报错，实际上什么都没做（之前版本可能覆盖了正确配置）。

### 修复
完全移除 `Get ALB URL` 和 `Update API URL in config` 两个步骤。

### 问题 4：health check 配置继承问题
即使 Dockerfile 加了 curl，pipeline render task definition 时仍从旧 revision 继承 `wget` 版本的 health check。

### 修复
Pipeline 加入 Python 脚本强制覆盖 health check：
```yaml
- name: Ensure health check uses curl
  run: |
    python3 -c "
    import json
    with open('...') as f:
        td = json.load(f)
    td['containerDefinitions'][0]['healthCheck'] = {
        'command': ['CMD-SHELL', 'curl -f http://localhost:8080/health || exit 1'],
        ...
    }
    ..."
```

---

## 三、CloudFront API HTTPS（Day 5 核心目标）

### 问题
前端是 HTTPS（CloudFront），API 是 HTTP（ALB），浏览器阻止混合内容：
```
Mixed Content: The page at 'https://...' was loaded over HTTPS,
but requested an insecure resource 'http://...'
```

### 解决方案
在 ALB 前面加一层 CloudFront distribution，提供 HTTPS 终止：
- 新建 `infra/cloudfront-api.tf`
- CloudFront origin 指向 ALB，使用 `http-only` 协议（ALB 只有 HTTP）
- viewer 端使用 `redirect-to-https`
- API CloudFront URL：`https://d60tbbl9t8f4g.cloudfront.net`
- 更新 `Resume.Web/wwwroot/appsettings.Production.json` 使用新 HTTPS URL

---

## 四、监控告警（CloudWatch + SNS）

### 新建 `infra/monitoring.tf`

**SNS Topic**：`resume-alerts`（ARN 已输出）

**CloudWatch Alarms**：
| Alarm | 条件 | 通知 |
|-------|------|------|
| ECS CPU | > 80%，连续 2 个周期 | SNS |
| ECS Memory | > 80%，连续 2 个周期 | SNS |
| ALB 5xx | > 10 次/5分钟 | SNS |
| RDS CPU | > 80%，连续 2 个周期 | SNS |

**CloudWatch Dashboard**：`resume-platform`
- ECS CPU & Memory 趋势图
- ALB 请求数 & 5xx 错误
- RDS CPU & 连接数
- ALB 响应时间（p99 & avg）

### 遇到的问题
1. IAM 权限不足：`SNS:CreateTopic`、`application-autoscaling:ListTagsForResource`、`cloudwatch:PutDashboard` 均被拒绝
2. CloudWatch Dashboard JSON 缺少 `region` 字段，12 个 validation error

### 修复
- 添加 inline policy `MonitoringAndScaling`（cloudwatch:* + application-autoscaling:*）
- 添加 managed policy `AmazonSNSFullAccess`（已达 10 个 policy 上限，改用 inline）
- Dashboard 每个 widget 的 properties 加入 `region = var.aws_region`

---

## 五、ECS Auto Scaling

### 新建 `infra/autoscaling.tf`
- `aws_appautoscaling_target`：min 1，max 5 个任务
- CPU scaling policy：目标 70%，scale out 冷却 60s，scale in 冷却 300s
- Memory scaling policy：目标 70%，同上

---

## 六、SES 邮件通知

### 目标
有人提交联系表单 → 自动发邮件到 `mkuplift11@gmail.com`

### 实现
- SES 在 `ap-southeast-4`（Melbourne）不可用，改用 `ap-southeast-2`（Sydney）
- `infra/main.tf` 加入 alias provider `aws.ses`
- `infra/ses.tf` 验证邮箱 identity
- `Resume.Api/Resume.Api.csproj` 加入 `AWSSDK.SimpleEmail` NuGet 包
- `Resume.Api/Program.cs` 注入 `IAmazonSimpleEmailService`，POST /api/messages 成功后发邮件

### 遇到的问题 1：邮件没有收到
第一版代码用 `app.Logger.LogWarning` 记录错误，但 minimal API lambda 里这个 logger 不输出到 CloudWatch。

### 修复
改用 `ILogger<Program>` 注入，加入详细日志：
```csharp
async (ContactMessage message, AppDbContext db, IAmazonSimpleEmailService ses, ILogger<Program> logger)
```

### 遇到的问题 2：邮件进了 Gmail Spam
SES sandbox 模式发出的邮件 Gmail 判为垃圾邮件，因为 SPF/DKIM 不匹配（发件人是 gmail.com 但通过 AWS 服务器发出）。

### 解决
- 短期：手动把邮件移出 spam，Gmail 记住发件人
- 长期：申请 SES Production Access，或使用自定义域名邮箱

### ECS Task Role 权限
给 `resume-ecs-task-role` 加入 SES 发送权限：
```json
{ "Action": ["ses:SendEmail", "ses:SendRawEmail"], "Resource": "*" }
```

---

## 七、节省 AWS 费用脚本

### 账单分析（Mar 26）
| 服务 | 费用 |
|------|------|
| RDS | $17.50 |
| VPC | $10.33 |
| ALB | $7.71 |
| ECS | $5.67 |
| CloudWatch | $1.67 |

### 解决方案
新建 `scripts/stop-dev.sh` 和 `scripts/start-dev.sh`：
- 停止：ECS desired count → 0，RDS stop（停止状态只收存储费）
- 启动：RDS start → 等待 available → ECS desired count → 1
- ALB 无法停止，但无流量时费用极低

---

## 八、前端 UI 重新设计

### 设计参考
Xenta（xenta.com.au）风格：纯黑背景 + 品红渐变高亮 + 大标题 + 简洁导航

### 主要变化
- 全新 `app.css`：CSS 变量系统，Inter 字体，品红色 `#e91e8c`
- 固定顶部导航栏（sticky navbar）+ 右上角品红 CTA 按钮
- Hero 区域：左文字右圆形照片布局
  - `Hello, I'm Michael Li`（Michael Li 品红渐变）
  - `Cloud Engineer. Build. Deploy. Scale.`（Build. Deploy. Scale. 品红渐变）
  - 圆形照片 + 品红发光边框
- 卡片式 What I Do、Skills、Projects 区域
- 联系表单两列布局（Name + Email 并排）
- 响应式：移动端单列，照片居中

### 遇到的问题
1. 照片偏左 → 给 `.hero-right` 和 `.hero-photo-wrap` 加 `margin: 0 auto` 和 `justify-content: center`
2. Michael Li 颜色不对 → 补充 `.hero-greeting .highlight` 渐变样式

### 其他 UI 改进
- Favicon 换成 SVG（ML 品红渐变，黑色圆角背景）
- icon-192 同样换成 SVG
- 页面 title 改为 `Michael Li · Cloud Engineer`
- Get in Touch 按钮用 JavaScript `scrollIntoView` 跳转到联系表单
- smooth scroll 全局启用

---

## 九、基础设施变更汇总

| 文件 | 变更 |
|------|------|
| `infra/cloudfront-api.tf` | 新建，API CloudFront distribution |
| `infra/monitoring.tf` | 新建，SNS + CloudWatch Alarms + Dashboard |
| `infra/autoscaling.tf` | 新建，ECS Auto Scaling |
| `infra/ses.tf` | 新建，SES email identity |
| `infra/ecs.tf` | 加 SES IAM policy，health check 改 curl，lifecycle ignore_changes |
| `infra/main.tf` | 加 SES alias provider（ap-southeast-2）|
| `Resume.Api/Dockerfile` | 加 curl 安装 |
| `Resume.Api/Program.cs` | 加 SES 邮件发送逻辑 |
| `.github/workflows/deploy.yml` | 修复 task def 动态获取，移除 sed，加 health check 强制覆盖 |

---

## 十、当前系统状态

| 组件 | 状态 | URL |
|------|------|-----|
| 前端 | ✅ 运行中 | https://ddcfte7n5r9tt.cloudfront.net |
| API | ✅ 运行中 | https://d60tbbl9t8f4g.cloudfront.net |
| 数据库 | ✅ 运行中 | resume-db.cpqckaaqa750.ap-southeast-4.rds.amazonaws.com |
| ECS | ✅ Running: 1 | resume-cluster / resume-api-service |
| 监控 | ✅ 4 个 Alarm | CloudWatch Dashboard: resume-platform |
| 邮件通知 | ✅ 正常（注意 spam） | mkuplift11@gmail.com |

---

## 待办事项（Day 6+）
- [ ] 放入 CV PDF（`Resume.Web/wwwroot/assets/Michael-Li-CV.pdf`）
- [ ] SES 申请 Production Access（移出 sandbox）
- [ ] 自定义域名（Route53）
- [ ] ECS Exec 开启（方便容器内调试）
