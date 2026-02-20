# RDS PostgreSQL 部署指南

## 快速开始

### 1. 获取你的公网 IP
```bash
curl ifconfig.me
```

### 2. 更新 terraform.tfvars
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

编辑 `terraform.tfvars`，设置：
- `db_password`: 强密码
- `my_ip`: 你的公网 IP/32（例如：`203.123.45.67/32`）

### 3. 部署 RDS
```bash
terraform plan
terraform apply
```

等待 5-10 分钟创建完成。

### 4. 获取连接信息
```bash
terraform output rds_address
terraform output -raw rds_connection_string
```

### 5. 更新 API 配置
编辑 `Resume.Api/appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=YOUR_RDS_ADDRESS;Port=5432;Database=resume;Username=postgres;Password=YOUR_PASSWORD"
  }
}
```

### 6. 运行数据库迁移
```bash
cd Resume.Api
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## 架构说明

- 使用默认 VPC 和子网
- RDS 公开访问（仅限你的 IP）
- db.t3.micro 实例
- 20GB gp3 存储
- 7 天自动备份

## 后续步骤（API 上 ECS 后）

当 API 部署到 ECS 后，运行：

```bash
# 修改 RDS 为私有访问
terraform apply -var="publicly_accessible=false"

# 更新 SG 规则允许 ECS 访问
# 在 rds.tf 中添加 ECS SG 的 ingress 规则
```

## 成本估算

- db.t3.micro: ~$15-20/月
- 20GB 存储: ~$2.30/月
- 总计: ~$17-22/月

## 临时停用（节省成本）

```bash
# 仅删除 RDS（保留 VPC 和其他资源）
terraform destroy -target=aws_db_instance.postgres
```

## 安全提示

⚠️ 当前配置仅用于开发！生产环境需要：
- 设置 `publicly_accessible = false`
- 使用 VPN 或 Bastion Host
- 使用 AWS Secrets Manager 管理密码
- 启用加密
