#!/bin/bash

# Railway Deployment Script for RepAlign Backend
# Run this script from the backend directory

set -e  # Exit on any error

echo "🚂 Starting Railway deployment..."

# Add PostgreSQL (you'll need to select "Database" -> "PostgreSQL" in the interactive menu)
echo ""
echo "Step 1: Adding PostgreSQL database..."
echo "When prompted:"
echo "  - Select: Database"
echo "  - Select: PostgreSQL"
echo ""
railway add

# Set environment variables
echo ""
echo "Step 2: Setting environment variables..."

railway variables set NODE_ENV=production
railway variables set JWT_SECRET="X5ITJptYdEC2bW/y++4r7ideU21K7YA+Ox1hd9N0heE="
railway variables set JWT_REFRESH_SECRET="DGn3VTFd1I/G1uyQ8U3NFj9w/pP0WJfcU2SnfvgPklc="
railway variables set JWT_EXPIRATION_TIME=15m
railway variables set JWT_REFRESH_EXPIRATION_TIME=7d
railway variables set CONGRESS_API_KEY=T0XwPfaktNaBrwqCYjUbEngqJwkLfvw3cuOEy8pp
railway variables set API_PREFIX=api/v1
railway variables set PORT=3000

echo "✅ Environment variables set"

# Deploy the backend
echo ""
echo "Step 3: Deploying backend..."
railway up --detach

echo ""
echo "⏳ Deployment initiated. Checking status..."
sleep 5

railway status

# Generate public domain
echo ""
echo "Step 4: Generating public domain..."
railway domain

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Check deployment logs: railway logs"
echo "2. Get your URL: railway domain (or check output above)"
echo "3. Run migrations: railway run npm run migration:run"
echo "4. Create test user in database"
echo ""
echo "Your Railway dashboard: https://railway.com/project/e2c83075-af97-4062-8497-441d431c60cd"
