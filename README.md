# Resume Platform - 30 Day Cloud Project

A full-stack cloud-native resume platform built on AWS, featuring Blazor WebAssembly frontend, .NET 8 API, and PostgreSQL database.

## 🏗️ Architecture

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

## 🚀 Tech Stack

### Frontend
- **Blazor WebAssembly** (.NET 7)
- **S3** - Static website hosting
- **CloudFront** - CDN with Origin Access Control (OAC)

### Backend
- **.NET 8** - Web API
- **Docker** - Containerization
- **ECS Fargate** - Serverless container orchestration
- **ECR** - Container registry
- **Application Load Balancer** - API gateway

### Database
- **RDS PostgreSQL** - Managed database
- **Entity Framework Core** - ORM

### Infrastructure
- **Terraform** - Infrastructure as Code
- **GitHub Actions** - CI/CD pipeline
- **AWS Secrets Manager** - Secrets management
- **CloudWatch Logs** - Logging and monitoring

## 📋 Features

✅ Responsive resume website  
✅ Contact form with backend API  
✅ Message storage in PostgreSQL  
✅ Containerized API deployment  
✅ Auto-scaling capable (ECS Fargate)  
✅ Secure secrets management  
✅ Automated CI/CD pipeline  
✅ CloudWatch logging and monitoring  

## 🎯 Project Timeline

### Day 1-2: Frontend Setup
- ✅ Blazor WebAssembly application
- ✅ S3 bucket with CloudFront
- ✅ Origin Access Control (OAC)
- ✅ GitHub Actions deployment

### Day 3: Backend API & Database
- ✅ .NET 8 Web API
- ✅ RDS PostgreSQL database
- ✅ Entity Framework Core
- ✅ API endpoints (GET/POST)
- ✅ AWS Secrets Manager integration
- ✅ User Secrets for local development

### Day 4: Containerization & ECS
- ✅ Docker containerization
- ✅ ECR repository
- ✅ ECS Fargate deployment
- ✅ Application Load Balancer
- ✅ Frontend-Backend integration
- ✅ CI/CD automation

### Day 5+: Future Enhancements
- ⬜ HTTPS with ACM certificate
- ⬜ Custom domain with Route53
- ⬜ ECS Auto-scaling
- ⬜ CloudWatch Alarms
- ⬜ AWS WAF
- ⬜ Performance optimization

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform installed
- Docker installed
- .NET 8 SDK
- Git

### Deploy Everything
```bash
# Clone repository
git clone <your-repo-url>
cd resume-platform

# Deploy infrastructure and API
./deploy-day4.sh

# Or deploy manually
cd infra
terraform init
terraform apply
./deploy-api.sh
```

### Local Development
```bash
# Run API locally
cd Resume.Api
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "YOUR_CONNECTION_STRING"
dotnet run

# Run frontend locally
cd Resume.Web
dotnet run
```

## 📚 Documentation

- [Day 4 Deployment Guide](DAY4-DEPLOYMENT.md) - Complete deployment walkthrough
- [Day 4 Summary](SUMMARY-DAY4.md) - What was accomplished
- [Quick Reference](QUICK-REFERENCE.md) - Common commands and URLs
- [ECS Deployment Details](infra/README-ECS.md) - ECS architecture and troubleshooting
- [IAM Setup for ECS](infra/IAM-SETUP-ECS.md) - Required permissions
- [Security Checklist](SECURITY-CHECKLIST.md) - Security best practices

## 🔗 Live URLs

- **Frontend**: https://ddcfte7n5r9tt.cloudfront.net
- **API**: Run `terraform output api_url` to get ALB URL
- **RDS**: `resume-db.cpqckaaqa750.ap-southeast-4.rds.amazonaws.com`

## 💰 Cost Estimate

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| ECS Fargate | 1 task, 0.25 vCPU, 512 MB | ~$10 |
| ALB | Basic + data transfer | ~$16 |
| RDS | db.t3.micro, 20GB | Free tier |
| S3 | Static hosting | Free tier |
| CloudFront | CDN | Free tier |
| ECR | 500 MB storage | Free tier |
| CloudWatch Logs | 5 GB/month | Free tier |
| Secrets Manager | 1 secret | $0.40 |
| **Total** | | **~$26.40/month** |

## 🔐 Security

- ✅ Secrets stored in AWS Secrets Manager
- ✅ IAM roles with least privilege
- ✅ Security groups restrict traffic
- ✅ No hardcoded credentials
- ✅ ECR image scanning enabled
- ✅ CloudWatch logging enabled
- ✅ User Secrets for local development

## 🧪 Testing

### Test API
```bash
# Get ALB URL
ALB_DNS=$(aws elbv2 describe-load-balancers --names resume-api-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-southeast-4)

# Health check
curl http://${ALB_DNS}/health

# Get messages
curl http://${ALB_DNS}/api/messages

# Post message
curl -X POST http://${ALB_DNS}/api/messages \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","message":"Hello!"}'
```

### View Logs
```bash
aws logs tail /ecs/resume-api --follow --region ap-southeast-4
```

## 📊 Monitoring

- **CloudWatch Logs**: `/ecs/resume-api`
- **ECS Service Metrics**: Container Insights enabled
- **ALB Metrics**: Request count, latency, error rates
- **RDS Metrics**: CPU, connections, storage

## 🛠️ Troubleshooting

See [Quick Reference](QUICK-REFERENCE.md) for common commands and troubleshooting steps.

Common issues:
- Container won't start → Check CloudWatch logs
- Database connection failed → Verify security groups
- ALB health check failing → Check `/health` endpoint
- CORS errors → Update API CORS configuration

## 🤝 Contributing

This is a personal learning project, but feedback and suggestions are welcome!

## 📝 License

MIT License - feel free to use this as a template for your own projects.

## 👤 Author

**Michael Li**
- Email: michaelmk1122@gmail.com
- LinkedIn: [linkedin.com/in/-michael-li/](https://www.linkedin.com/in/-michael-li/)
- GitHub: [github.com/MK-Uplift](https://github.com/MK-Uplift)

## 🙏 Acknowledgments

Built as part of a 30-day cloud engineering learning project to demonstrate:
- Cloud-native architecture
- Infrastructure as Code
- CI/CD automation
- Container orchestration
- Security best practices
- Production-ready deployment

---

⭐ If you find this project helpful, please give it a star!
