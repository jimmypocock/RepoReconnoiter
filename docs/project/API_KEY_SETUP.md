# API Key Setup Guide (Recommended)

## 🎯 Best Practice: Separate Keys Per Environment

Use different API keys for development and production. This provides:
- ✅ Security isolation (dev compromise doesn't affect prod)
- ✅ Independent rotation
- ✅ Usage tracking per environment
- ✅ Revocation control

---

## 🚀 Setup Steps

### **1. Create Production Key (on Render)**

Go to Render Dashboard → Your App → Shell:

```bash
bin/rails api_keys:generate NAME="Next.js Production (Vercel)"
```

**Output:**
```
✅ API Key Generated Successfully!

Name:       Next.js Production (Vercel)
ID:         1
User:       System (no user)
Created:    2025-11-12 04:00:00 UTC

🔑 API Key: abc123def456...SAVE_THIS_NOW

⚠️  IMPORTANT: Save this key NOW! It will not be shown again.

To use in Next.js (Vercel env vars):
  API_KEY=abc123def456...
```

**Save this key** in your password manager!

---

### **2. Set Production Key on Vercel**

Vercel Dashboard → Your Project → Settings → Environment Variables:

```
Variable name:  API_KEY
Value:          abc123def456...
Environments:   Production
```

Click "Save" and redeploy.

---

### **3. Create Development Key (locally)**

On your local machine:

```bash
bin/rails api_keys:generate NAME="Next.js Development (Local)"
```

**Output:**
```
🔑 API Key: xyz789ghi012...SAVE_THIS_NOW
```

**Save this key** too!

---

### **4. Set Development Key Locally**

Add to your `.env` file (which is gitignored):

```bash
# .env
API_KEY=xyz789ghi012...
```

**Or** use ENV var fallback (works in dev/test only):

```bash
# .env
TRUSTED_API_KEYS=xyz789ghi012...
```

Both work, but `API_KEY` is preferred for Next.js consistency.

---

### **5. Test Locally**

```bash
# Test with your dev key
curl -H "Authorization: Bearer xyz789ghi012..." \
  http://localhost:3000/api/v1/comparisons
```

Should bypass rate limits and return data.

---

### **6. Verify Production (after Vercel deploy)**

```bash
# From Vercel server logs or test endpoint
curl -H "Authorization: Bearer abc123def456..." \
  https://api.reporeconnoiter.com/v1/comparisons
```

Should bypass rate limits.

---

## 🔐 Security Model

### **ENV Var Fallback (Development/Test Only)**

```ruby
# In rack_attack.rb
if Rails.env.development? || Rails.env.test?
  # ENV var fallback works
  trusted_api_keys = ENV["TRUSTED_API_KEYS"]
else
  # Production: Database only, ENV var ignored
  false
end
```

**Why this matters:**
- ✅ **Development**: Can use `.env` file before creating DB keys
- ✅ **Production**: MUST use database keys (more secure, tracked)
- ✅ **No accidental ENV var leaks** in production

### **Key Encryption (All Environments)**

```
Plain-text key:   abc123def456... (64 chars)
                  ↓ BCrypt hashing
Database storage: $2a$12$XyZ... (BCrypt hash)
```

Even if production database is compromised, keys cannot be recovered!

---

## 📊 Managing Keys

### **List All Keys**

```bash
# Locally
bin/rails api_keys:list

# On production (Render shell)
bin/rails api_keys:list
```

**Output:**
```
API Keys:

ID    Name                           User      Requests   Status   Last Used
--------------------------------------------------------------------------------
1     Next.js Production (Vercel)    System    1,427      Active   2025-11-12 04:55
2     Next.js Development (Local)    System    142        Active   2025-11-12 03:12

Total: 2 keys
Active: 2
Revoked: 0
```

### **View Usage Stats**

```bash
bin/rails api_keys:stats
```

**Output:**
```
API Key Statistics
==================================================

Total Keys:      2
Active:          2
Revoked:         0
Total Requests:  1,569

Most Used Keys (Top 5):

ID    Name                           Requests   Last Used
----------------------------------------------------------------------
1     Next.js Production (Vercel)    1,427      2025-11-12 04:55
2     Next.js Development (Local)    142        2025-11-12 03:12
```

### **Revoke a Key**

```bash
# If dev key is compromised
bin/rails api_keys:revoke ID=2

# If prod key is compromised (on Render shell)
bin/rails api_keys:revoke ID=1
```

Then generate a new one and update Vercel env vars.

---

## 🔄 Key Rotation (Every 90 Days)

### **Rotate Development Key**

```bash
# 1. Generate new dev key
bin/rails api_keys:generate NAME="Next.js Development (Local) v2"
# Output: new_dev_key_abc...

# 2. Update .env
# Replace old key with new key

# 3. Test
curl -H "Authorization: Bearer new_dev_key_abc..." \
  http://localhost:3000/api/v1/comparisons

# 4. Revoke old key
bin/rails api_keys:revoke ID=2
```

### **Rotate Production Key**

```bash
# 1. Generate new prod key (on Render shell)
bin/rails api_keys:generate NAME="Next.js Production (Vercel) v2"
# Output: new_prod_key_xyz...

# 2. Update Vercel env var
#    Go to Vercel → Environment Variables
#    Update API_KEY to new_prod_key_xyz...

# 3. Redeploy Next.js on Vercel

# 4. Test production
curl -H "Authorization: Bearer new_prod_key_xyz..." \
  https://api.reporeconnoiter.com/v1/comparisons

# 5. Revoke old key (on Render shell)
bin/rails api_keys:revoke ID=1
```

**Set calendar reminder** for 90 days from now!

---

## 🆘 Troubleshooting

### **Dev key not working locally**

```bash
# Check if key exists
bin/rails runner "puts ApiKey.authenticate('your-key').inspect"
# Should show ApiKey record, not nil

# Check environment
bin/rails runner "puts Rails.env"
# Should show "development"

# Try ENV var fallback
# Add to .env:
TRUSTED_API_KEYS=your-key-here
```

### **Production key not working**

```bash
# On Render shell, check if key exists
bin/rails runner "puts ApiKey.find(1).inspect"

# Check if key is revoked
bin/rails runner "puts ApiKey.find(1).revoked_at"
# Should be nil if active

# Verify Vercel env var is set
# Go to Vercel → Environment Variables
# Ensure API_KEY is set and deployed
```

### **ENV var fallback not working in production (GOOD!)**

**This is by design!** Production ONLY uses database keys for security.

If you accidentally relied on ENV vars in production:

```bash
# On Render shell, generate a database key
bin/rails api_keys:generate NAME="Production Replacement"

# Update Vercel with the new database key
# Old ENV var will be ignored in production
```

---

## ✅ Recommended Setup Summary

```
Development (Local):
├─ Database key: "Next.js Development (Local)"
├─ Stored in: .env file
└─ Fallback: TRUSTED_API_KEYS (optional)

Production (Render):
├─ Database key: "Next.js Production (Vercel)"
├─ Stored in: Vercel env vars
└─ Fallback: None (database only!)

Staging (if needed):
├─ Database key: "Next.js Staging"
├─ Stored in: Vercel staging env vars
└─ Fallback: None
```

---

## 🎯 Quick Reference

```bash
# Generate new key
bin/rails api_keys:generate NAME="Key Name"

# List all keys
bin/rails api_keys:list

# View stats
bin/rails api_keys:stats

# Revoke key
bin/rails api_keys:revoke ID=123

# Clean up old revoked keys (90+ days)
bin/rails api_keys:cleanup

# Test authentication (Ruby)
bin/rails runner "puts ApiKey.authenticate('your-key').inspect"
```

---

## 📚 Related Docs

- **API Key Model**: `docs/project/API_KEY_MODEL.md` (detailed implementation)
- **API Auth Guide**: `docs/project/API_AUTH_GUIDE.md` (Next.js integration)
- **Security**: `docs/project/SECURITY.md` (overall security strategy)

---

## 🔒 Security Checklist

- [ ] Separate keys for dev and prod
- [ ] Production keys stored in database (not ENV vars)
- [ ] Dev keys in `.env` (gitignored)
- [ ] Prod keys in Vercel env vars (server-side only)
- [ ] Keys saved in password manager
- [ ] 90-day rotation reminder set
- [ ] Old keys revoked after rotation
- [ ] No API keys committed to git
- [ ] No API keys in browser (Next.js client-side)
