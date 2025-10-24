# Railway Deployment Guide for RepAlign Backend

## Quick Setup Commands

### 1. Install Railway CLI
```bash
# Using npm
npm install -g @railway/cli

# OR using Homebrew (recommended for macOS)
brew install railway
```

### 2. Login to Railway
```bash
railway login
```
This will open your browser for authentication.

### 3. Initialize Project (from backend directory)
```bash
cd /Users/xilinliu/Projects/RepAlign/backend
railway init
```
- Select "Create new project"
- Name it "repalign-backend" or similar

### 4. Add PostgreSQL Database
```bash
railway add
```
- Select "PostgreSQL"

### 5. Set Environment Variables

Generate strong secrets first:
```bash
# Generate JWT secrets (run these and copy the output)
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 32  # For JWT_REFRESH_SECRET
```

Set variables:
```bash
railway variables set NODE_ENV=production
railway variables set JWT_SECRET=<paste_first_secret_here>
railway variables set JWT_REFRESH_SECRET=<paste_second_secret_here>
railway variables set JWT_EXPIRATION_TIME=15m
railway variables set JWT_REFRESH_EXPIRATION_TIME=7d
railway variables set CONGRESS_API_KEY=T0XwPfaktNaBrwqCYjUbEngqJwkLfvw3cuOEy8pp
railway variables set API_PREFIX=api/v1
railway variables set PORT=3000
```

**Note:** Railway automatically sets `DATABASE_URL` for PostgreSQL, so you don't need to set it manually.

### 6. Deploy Backend
```bash
railway up
```

Watch the deployment logs in your terminal. This will:
- Build your NestJS app
- Start the production server
- Deploy to Railway's infrastructure

### 7. Generate Domain
```bash
railway domain
```
This creates a public URL like: `repalign-backend-production.up.railway.app`

**Copy this URL - you'll need it for the iOS app!**

### 8. Run Database Migrations
```bash
railway run npm run migration:run
```

If migrations fail or don't exist, you can use synchronize (development only):
```bash
# This is already set in your code when DATABASE_TYPE=postgres
# TypeORM will auto-create tables on first run
```

### 9. Create Test User

Connect to the production database:
```bash
railway connect postgres
```

Then run this SQL:
```sql
INSERT INTO users (
  username,
  email,
  password,
  display_name,
  user_type,
  email_verified,
  onboarding_completed,
  posts_count,
  followers_count,
  following_count,
  is_verified,
  last_active,
  created_at,
  updated_at
) VALUES (
  'johngoncalves',
  'johngoncalves@hks.harvard.edu',
  '$2a$10$u9LzvdAxlF4TUAxWUgA51eqZod5fJzraW6pi1rXCCXUr8yhXZBe..',
  'John Goncalves',
  'citizen',
  true,
  false,
  0,
  0,
  0,
  false,
  NOW(),
  NOW(),
  NOW()
);
```

Exit psql: `\q`

### 10. Verify Deployment

Test your API:
```bash
curl https://your-railway-domain.up.railway.app/api/v1

# Test login
curl -X POST https://your-railway-domain.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"johngoncalves@hks.harvard.edu","password":"ABCdef123"}'
```

---

## Useful Railway Commands

```bash
# View logs
railway logs

# Open Railway dashboard
railway open

# Check service status
railway status

# List environment variables
railway variables

# Connect to PostgreSQL
railway connect postgres

# Redeploy
railway up --detach
```

---

## Troubleshooting

### Build Fails
- Check logs: `railway logs`
- Ensure `package.json` has correct `build` script
- Verify Node version compatibility

### Database Connection Issues
- Railway auto-sets `DATABASE_URL`
- Check if TypeORM is reading it correctly
- Verify migrations ran: `railway run npm run migration:run`

### 502/503 Errors
- Check if app is listening on correct PORT
- Railway sets `PORT` env var - your app should use `process.env.PORT`
- Check health check endpoint is accessible

### Can't Access API
- Verify domain is generated: `railway domain`
- Check CORS settings in `main.ts`
- Ensure healthcheck path exists

---

## Next Steps

Once deployed, give Claude the Railway production URL so the iOS app can be updated!

**Your Railway URL will be:** `https://[project-name]-[environment].up.railway.app`
