# IAM 权限设置指南

## 需要的权限

你的 IAM 用户需要以下权限来运行 Terraform：

### 1. S3 和 CloudFront（已有）
- ✅ S3 完整访问
- ✅ CloudFront 完整访问

### 2. VPC 和网络（需要添加）
- ❌ 查看 VPC、子网
- ❌ 创建/管理 Security Groups
- ❌ 管理 Security Group 规则

### 3. RDS（需要添加）
- ❌ 创建/删除/修改 RDS 实例
- ❌ 创建/管理 DB Subnet Groups
- ❌ 查看 RDS 相关资源

## 快速设置（推荐）

### 方法 1：使用托管策略（最简单）

1. 进入 AWS Console → IAM → Users → MK-Uplift-11
2. 点击 "Add permissions" → "Attach policies directly"
3. 搜索并添加以下策略：
   - ✅ `AmazonS3FullAccess` (已有)
   - ✅ `CloudFrontFullAccess` (已有)
   - ➕ `AmazonVPCReadOnlyAccess` (新增)
   - ➕ `AmazonRDSFullAccess` (新增)
   - ➕ `AmazonEC2FullAccess` (新增 - 用于管理 Security Groups)

### 方法 2：使用自定义策略（最小权限）

1. 进入 AWS Console → IAM → Policies
2. 点击 "Create policy"
3. 选择 JSON 标签
4. 复制 `iam-policy.json` 的内容
5. 点击 "Next" → 命名为 `ResumeProjectPolicy`
6. 创建后，回到 Users → MK-Uplift-11
7. Attach 这个新策略

## 验证权限

添加权限后，运行：

```bash
cd infra
terraform plan
```

如果还有权限错误，查看错误信息中的 `Action` 字段，添加到策略中。

## 常见权限错误

| 错误信息 | 需要的权限 |
|---------|-----------|
| `ec2:DescribeVpcs` | VPC 读取权限 |
| `ec2:CreateSecurityGroup` | Security Group 创建权限 |
| `rds:CreateDBInstance` | RDS 创建权限 |
| `rds:CreateDBSubnetGroup` | DB Subnet Group 权限 |

## 生产环境建议

⚠️ 当前配置给予了较大权限，适合开发/学习。

生产环境应该：
- 使用 IAM Roles 而不是 IAM Users
- 实施最小权限原则
- 使用 AWS Organizations 和 SCPs
- 启用 CloudTrail 审计
- 定期轮换访问密钥
