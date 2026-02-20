# Resume API

## Local Development Setup

### 1. Configure Database Connection (User Secrets)

```bash
# Initialize user secrets (already done)
dotnet user-secrets init

# Set connection string
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=YOUR_RDS_ENDPOINT;Port=5432;Database=resume;Username=postgres;Password=YOUR_PASSWORD"
```

Get the connection string from Terraform:
```bash
cd ../infra
terraform output -raw rds_connection_string
```

### 2. Run Migrations

```bash
dotnet ef database update
```

### 3. Run API

```bash
dotnet run
```

Visit: `http://localhost:5082/swagger`

## Production Deployment

For production (ECS/AWS), use:
- **AWS Secrets Manager** - Store connection string
- **Environment Variables** - Set in ECS task definition

Connection string will be injected at runtime, never committed to Git.

## Security Notes

- ✅ User Secrets for local development (stored in `~/.microsoft/usersecrets/`)
- ✅ AWS Secrets Manager for production
- ✅ Connection string NOT in appsettings.json
- ✅ Safe to commit to Git
