# Render Deployment Guide

Complete guide for deploying RepoReconnoiter to Render.com.

## Prerequisites

- Render.com account
- GitHub repository connected to Render
- GitHub OAuth App credentials (for production)
- OpenAI API key
- Starter plan ($7/month) recommended for initial setup (provides shell access)

---

## Step 1: Create PostgreSQL Database

1. Log into Render Dashboard
2. Click "New +" → "PostgreSQL"
3. Configure database:
   - **Name**: `repo-reconnoiter-db` (or your preferred name)
   - **Database**: `repo_reconnoiter_production`
   - **User**: `repo_reconnoiter`
   - **Region**: Same region as your web service (for performance)
   - **PostgreSQL Version**: 17
   - **Plan**: Free tier is fine for MVP
4. Click "Create Database"
5. **Save the Internal Database URL** - you'll need this for the web service

Example Internal Database URL format:

```
postgres://repo_reconnoiter:PASSWORD@dpg-xxxxx/repo_reconnoiter_production
```

---

## Step 2: Create Web Service

1. In Render Dashboard, click "New +" → "Web Service"
2. Connect your GitHub repository
3. Configure the service:

### Basic Settings

- **Name**: `reporeconnoiter` (or your preferred name)
- **Region**: Same as database
- **Branch**: `main`
- **Root Directory**: Leave blank
- **Runtime**: Ruby
- **Build Command**:

  ```bash
  bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate
  ```

- **Start Command**:

  ```bash
  bundle exec puma -C config/puma.rb
  ```

### Environment Variables

Click "Advanced" and add these environment variables:

| Key | Value | Notes |
|-----|-------|-------|
| `DATABASE_URL` | `[Internal Database URL from Step 1]` | PostgreSQL connection string |
| `SECRET_KEY_BASE` | `[Generate with: bin/rails secret]` | Rails secret key |
| `RAILS_MASTER_KEY` | `[Copy from config/master.key]` | Decrypts credentials.yml.enc |
| `RAILS_ENV` | `production` | |
| `RAILS_LOG_LEVEL` | `info` | |
| `RAILS_SERVE_STATIC_FILES` | `true` | |
| `WEB_CONCURRENCY` | `2` | Puma workers (auto-set by Render) |
| `GITHUB_CLIENT_ID` | `[Your production OAuth App ID]` | See GitHub OAuth Setup below |
| `GITHUB_CLIENT_SECRET` | `[Your production OAuth App Secret]` | |
| `OPENAI_ACCESS_TOKEN` | `[Your OpenAI API key]` | From platform.openai.com |
| `CLARITY_PROJECT_ID` | `[Your Clarity project ID]` | Optional - Microsoft Clarity analytics |
| `MISSION_CONTROL_ADMIN_IDS` | `[Comma-separated GitHub IDs]` | For /jobs dashboard access |

### Instance Type

- **Free tier** works for testing
- **Starter ($7/month)** recommended - provides shell access for debugging

4. Click "Create Web Service"

---

## Step 3: GitHub OAuth Setup (Production)

You need a separate GitHub OAuth App for production.

1. Go to <https://github.com/settings/developers>
2. Click "New OAuth App"
3. Configure:
   - **Application name**: RepoReconnoiter (Production)
   - **Homepage URL**: `https://your-app-name.onrender.com`
   - **Authorization callback URL**: `https://your-app-name.onrender.com/users/auth/github/callback`
4. Click "Register application"
5. Copy the **Client ID** and generate a **Client Secret**
6. Add these to Render environment variables (see Step 2)

---

## Step 4: Initial Database Setup

After the first deploy completes, the database will be connected but empty (no tables). You need to run one-time setup commands.

### Option A: Using Render Shell (Recommended - requires Starter plan)

1. Go to Render Dashboard → Your Web Service → "Shell" tab
2. Run these commands:

```bash
# Load Solid Cache schema (Rails 8 database-backed cache)
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:cache

# Load Solid Queue schema (Rails 8 background jobs)
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:queue

# Load Solid Cable schema (Rails 8 WebSockets)
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:cable

# Seed the database (creates categories)
bin/rails db:seed
```

**Note**: The `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` is safe here - we're just creating infrastructure tables in empty databases for the first time.

### Option B: Temporary Build Command (Free tier workaround)

If you can't access the shell, temporarily update your build command:

```bash
bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate && DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:schema:load:cache db:schema:load:queue db:schema:load:cable && bundle exec rails db:seed
```

After successful deploy, **change it back** to the standard build command:

```bash
bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate
```

---

## Step 5: Admin Access Setup

The app uses an invite-only whitelist system. To grant yourself admin access:

### 5A. Whitelist Your GitHub User

**Recommended Method** (uses rake task):

1. Open Render Shell (Dashboard → Shell tab)

2. Run the whitelist rake task:

   ```bash
   bin/rails whitelist:add[your_github_username]
   ```

   The task automatically:
   - Fetches your GitHub ID from GitHub API
   - Fetches your email
   - Creates the WhitelistedUser record

3. Note your GitHub ID from the output (you'll need it for the next step)

**Alternative Method** (manual):

```bash
# Open Rails console
bin/rails console

# Create whitelisted user manually
WhitelistedUser.create!(
  github_id: YOUR_GITHUB_ID,
  github_username: "your_username",
  reason: "Admin user",
  email: "your@email.com"
)

# Exit
exit
```

### 5B. Grant Admin Dashboard Access

1. In Render Dashboard → Environment Variables
2. Find `MISSION_CONTROL_ADMIN_IDS`
3. Set to your GitHub ID (from step 5A)
   - Single admin: `12345678`
   - Multiple admins: `12345678,87654321` (comma-separated)
4. Save changes (this will restart your app)

---

## Step 6: Verify Deployment

1. Visit your Render URL: `https://your-app-name.onrender.com`
2. Click "Sign in with GitHub"
3. Authorize the OAuth app
4. You should see the home page with stats

### Check Background Jobs

- Visit: `https://your-app-name.onrender.com/jobs`
- Should see Mission Control dashboard (if you're an admin)

### Verify Security Headers

- Visit: <https://securityheaders.com/>
- Enter your Render URL
- Should see A+ rating with CSP, HSTS, etc.

---

## Ongoing Deployments

For future code changes:

1. Push to `main` branch on GitHub
2. Render auto-deploys
3. Build command runs: `bundle install && rails assets:precompile && rails db:migrate`
4. Migrations run automatically (if any)
5. App restarts with new code

**No manual database setup needed** - migrations handle schema changes.

---

## Custom Domain Setup (Optional)

1. In Render Dashboard → Web Service → Settings → Custom Domains
2. Add your domain (e.g., `reporeconnoiter.com`)
3. Render provides DNS instructions
4. Update your DNS provider:
   - **A Record**: Point to Render's IP
   - **CNAME**: Point to `your-app.onrender.com`
5. Render auto-provisions SSL certificate via Let's Encrypt
6. Update GitHub OAuth callback URL to use your custom domain

---

## Environment Variables Reference

### Required

- `DATABASE_URL` - PostgreSQL connection string from Render
- `SECRET_KEY_BASE` - Rails encryption key (generate with `bin/rails secret`)
- `RAILS_MASTER_KEY` - Master key to decrypt credentials (copy from `config/master.key`)
- `GITHUB_CLIENT_ID` - GitHub OAuth App ID
- `GITHUB_CLIENT_SECRET` - GitHub OAuth App Secret
- `OPENAI_ACCESS_TOKEN` - OpenAI API key
- `MISSION_CONTROL_ADMIN_IDS` - GitHub IDs for /jobs dashboard access

### Optional

- `CLARITY_PROJECT_ID` - Microsoft Clarity analytics project ID
- `COMPARISON_SIMILARITY_THRESHOLD` - Query fuzzy matching (default: 0.8)
- `COMPARISON_CACHE_DAYS` - Cache TTL in days (default: 7)
- `RAILS_LOG_LEVEL` - Logging verbosity (default: info)
- `WEB_CONCURRENCY` - Puma workers (Render auto-sets based on plan)

---

## Known Issues

**Current Status**: ✅ No known issues!

The production deployment is stable and all features are working as expected:
- ✅ OAuth flow working
- ✅ AI comparisons functioning
- ✅ Background jobs processing
- ✅ Cost tracking operational
- ✅ Security headers configured (A+ rating)
- ✅ Custom domain with SSL active

If you encounter any issues, please check the Troubleshooting section below or report them via GitHub Issues.

---

## Troubleshooting

### Build Fails: "ActionMailer not found"

- **Fix**: Ensure `require "action_mailer/railtie"` is uncommented in `config/application.rb`
- We re-enabled ActionMailer for future email features

### Build Fails: "DATABASE_URL not set"

- **Fix**: Copy Internal Database URL from Render PostgreSQL dashboard
- Ensure it's set as `DATABASE_URL` environment variable

### Error: "Missing encryption key to decrypt credentials"

- **Fix**: Set `RAILS_MASTER_KEY` environment variable
- Copy the value from `config/master.key` in your local repo
- **Important**: Never commit `config/master.key` to git (already in `.gitignore`)

### 500 Error: "relation 'solid_cache_entries' does not exist"

- **Fix**: Run Step 4 commands to load Solid Cache/Queue/Cable schemas
- This is a one-time setup - future deploys won't need this

### OAuth Error: "redirect_uri_mismatch"

- **Fix**: Ensure GitHub OAuth callback URL matches your Render domain exactly
- Format: `https://your-app.onrender.com/users/auth/github/callback`

### Can't Access /jobs Dashboard

- **Fix**: Add your GitHub user ID to `MISSION_CONTROL_ADMIN_IDS` environment variable
- Format: `123456,789012` (comma-separated, no spaces)

### Database Connection Timeout

- **Fix**: Ensure web service and database are in the same region
- Check `DATABASE_URL` is the **Internal** URL (starts with `postgres://`)

---

## Rails 8 Multi-Database Architecture

RepoReconnoiter uses Rails 8's multi-database feature with a single PostgreSQL database:

- **Primary** (`db/schema.rb`) - Application data (repos, users, comparisons, etc.)
- **Cache** (`db/cache_schema.rb`) - Solid Cache tables for database-backed caching
- **Queue** (`db/queue_schema.rb`) - Solid Queue tables for background jobs
- **Cable** (`db/cable_schema.rb`) - Solid Cable tables for WebSocket connections

All four databases share the same PostgreSQL instance (via `DATABASE_URL`) but use separate schema files. This eliminates the need for Redis while maintaining performance.

---

## Cost Breakdown

**Free Tier:**

- PostgreSQL: Free (90 days)
- Web Service: Free (spins down after 15 min inactivity)
- **Total**: $0/month (good for testing)

**Starter Tier (Recommended):**

- PostgreSQL: $7/month (always-on, 1GB storage, 97 connections)
- Web Service: $7/month (always-on, 512MB RAM, shell access)
- **Total**: $14/month

**Additional Costs:**

- Custom domain SSL: Free (auto-provisioned)
- Bandwidth: 100GB/month free, then $0.10/GB
- OpenAI API: ~$5-10/month (based on usage)

---

## Next Steps

After successful deployment:

1. **Test the comparison flow**: Create a test comparison to ensure OpenAI integration works
2. **Monitor costs**: Check Render usage dashboard and OpenAI API dashboard
3. **Set up monitoring**: Consider adding error tracking (Sentry, Rollbar, etc.)
4. **Review logs**: Check Render logs for any warnings or errors
5. **Plan background jobs**: Trending repo sync job runs every 20 minutes (configured in `config/recurring.yml`)

---

## Support

- **Render Docs**: <https://render.com/docs>
- **Rails 8 Guides**: <https://guides.rubyonrails.org/>
- **Solid Queue**: <https://github.com/rails/solid_queue>
- **Issue Tracker**: [Your GitHub repo]/issues
