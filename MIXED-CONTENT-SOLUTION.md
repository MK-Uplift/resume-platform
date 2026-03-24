# 混合内容问题解决方案

## 🔴 问题

浏览器阻止了从 HTTPS 网站（CloudFront）调用 HTTP API（ALB）：

```
Mixed Content: The page at 'https://ddcfte7n5r9tt.cloudfront.net/' was loaded over HTTPS, 
but requested an insecure resource 'http://resume-api-alb-782268297.ap-southeast-4.elb.amazonaws.com/api/messages'. 
This request has been blocked; the content must be served over HTTPS.
```

这是浏览器的安全策略，防止 HTTPS 页面加载不安全的 HTTP 资源。

## ✅ 解决方案

### 方案 1: 临时测试（通过 HTTP 访问前端）

**仅用于测试，不推荐生产环境！**

访问前端的 HTTP 版本（通过 S3）：
```
http://mk-uplift-resume-web.s3-website.ap-southeast-4.amazonaws.com
```

这样可以从 HTTP 页面调用 HTTP API。

**步骤：**
1. 获取 S3 网站 URL：
   ```bash
   aws s3api get-bucket-website --bucket mk-uplift-resume-web --region ap-southeast-4
   ```

2. 访问 `http://mk-uplift-resume-web.s3-website.ap-southeast-4.amazonaws.com`

3. 测试联系表单

### 方案 2: 为 ALB 配置 HTTPS（推荐）

这是生产环境的正确方案。

#### 步骤 1: 申请 SSL 证书（AWS Certificate Manager）

1. 打开 ACM 控制台：https://console.aws.amazon.com/acm/
2. 点击 "Request certificate"
3. 选择 "Request a public certificate"
4. 输入域名（如果有自定义域名）或使用 CloudFront 域名
5. 选择 DNS 验证
6. 等待证书颁发

#### 步骤 2: 更新 ALB 配置

添加 HTTPS 监听器到 `infra/alb.tf`：

```hcl
# HTTPS Listener (需要 ACM 证书)
resource "aws_lb_listener" "api_https" {
  load_balancer_arn = aws_lb.api.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:REGION:ACCOUNT:certificate/CERT_ID"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# HTTP to HTTPS 重定向
resource "aws_lb_listener" "api_http_redirect" {
  load_balancer_arn = aws_lb.api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

#### 步骤 3: 更新前端配置

更新 `Resume.Web/wwwroot/appsettings.Production.json`：
```json
{
  "ApiBaseUrl": "https://resume-api-alb-782268297.ap-southeast-4.elb.amazonaws.com"
}
```

#### 步骤 4: 部署

```bash
cd infra
terraform apply

# 重新部署前端
git add .
git commit -m "Add HTTPS support for ALB"
git push origin main
```

### 方案 3: 使用自签名证书（开发测试）

**仅用于开发测试！**

1. 生成自签名证书
2. 上传到 ACM
3. 配置 ALB HTTPS 监听器
4. 浏览器会显示安全警告，需要手动接受

## 🚀 快速测试（方案 1）

如果你只是想快速测试功能，使用方案 1：

```bash
# 1. 启用 S3 网站托管（如果还没有）
aws s3 website s3://mk-uplift-resume-web/ \
  --index-document index.html \
  --region ap-southeast-4

# 2. 更新 S3 bucket 策略允许公开访问
# (已经配置了 CloudFront OAC，可能需要额外配置)

# 3. 访问 HTTP 版本
echo "访问: http://mk-uplift-resume-web.s3-website.ap-southeast-4.amazonaws.com"
```

## 📊 当前状态

✅ **后端 API**: 正常运行
- URL: http://resume-api-alb-782268297.ap-southeast-4.elb.amazonaws.com
- 健康检查: ✅ 通过
- 数据库连接: ✅ 正常
- CORS: ✅ 已配置

✅ **前端**: 正常部署
- CloudFront (HTTPS): https://ddcfte7n5r9tt.cloudfront.net
- S3 (HTTP): 需要配置

❌ **问题**: 混合内容阻止
- HTTPS 前端无法调用 HTTP API

## 💡 推荐方案

**短期（今天）**: 使用方案 1 测试功能

**长期（Day 5）**: 实施方案 2
- 申请 ACM 证书
- 配置 ALB HTTPS
- 可选：配置自定义域名

## 📝 Day 5 计划

1. 申请 ACM 证书
2. 为 ALB 添加 HTTPS 监听器
3. 配置 HTTP → HTTPS 重定向
4. 更新前端配置使用 HTTPS API
5. （可选）配置自定义域名

## 🔗 相关文档

- [AWS ACM 文档](https://docs.aws.amazon.com/acm/)
- [ALB HTTPS 配置](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)
- [混合内容说明](https://developer.mozilla.org/en-US/docs/Web/Security/Mixed_content)

---

**当前建议**: 使用方案 1 快速测试，Day 5 实施 HTTPS 方案。
