# GitHub Actions CI/CD Setup

## Required Secrets

Add these secrets to your GitHub repository:

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

### AWS_ACCESS_KEY_ID
Your IAM user's access key ID

### AWS_SECRET_ACCESS_KEY
Your IAM user's secret access key

## How It Works

The workflow triggers on:
- Push to `main` branch
- Manual trigger via GitHub Actions UI

## Workflow Steps

1. Checkout code
2. Setup .NET 7.0
3. Restore dependencies
4. Build the Blazor app
5. Publish to Release configuration
6. Deploy to S3 bucket
7. Invalidate CloudFront cache

## Manual Deployment

You can manually trigger the workflow:
1. Go to **Actions** tab
2. Select **Deploy to AWS**
3. Click **Run workflow**
4. Select branch and click **Run workflow**

## Monitoring

Check deployment status in the **Actions** tab of your repository.
