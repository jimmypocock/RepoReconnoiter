# Deployment Guide: Route 53 + Vercel + Render + Cloudflare

This guide walks through deploying RepoReconnoiter with:
- **Frontend**: Next.js on Vercel (`reporeconnoiter.com`)
- **API**: Rails on Render (`api.reporeconnoiter.com`)
- **DNS**: Route 53 (AWS)
- **Protection**: Cloudflare (optional but recommended)

---

## 🎯 Architecture Overview

```
User Request
    ↓
Route 53 DNS (reporeconnoiter.com)
    ↓
┌─────────────────┬─────────────────┐
│                 │                 │
Vercel            Render
(Next.js)         (Rails API)
reporeconnoiter   api.reporeconnoiter
.com              .com
```

---

## 📋 Step-by-Step Setup

### **Phase 1: Deploy Rails API to Render** (Already Done)

✅ Your Rails app is already on Render
✅ Note your Render app URL: `your-app.onrender.com`

**Environment Variables to Set on Render:**

```bash
# Required - Generate with: bin/rails secret
SECRET_KEY_BASE=<your-secret-key>

# Required - From config/master.key
RAILS_MASTER_KEY=<your-master-key>

# Required - OpenAI API key
OPENAI_ACCESS_TOKEN=<your-openai-key>

# Required - GitHub OAuth credentials
GITHUB_CLIENT_ID=<your-github-client-id>
GITHUB_CLIENT_SECRET=<your-github-client-secret>

# Required - Admin access (your GitHub user ID)
ALLOWED_ADMIN_GITHUB_IDS=<your-github-id>

# NEW - API key for Next.js server (generate random 32-char string)
TRUSTED_API_KEYS=<random-api-key-here>

# Optional - Next.js frontend URL (for CORS)
NEXTJS_DOMAIN=https://reporeconnoiter.com

# Optional - Comma-separated IPs to block
BLOCKED_IPS=

# Optional - Sentry DSN for error tracking
SENTRY_DSN=
```

**Generate API Key:**
```bash
# On your local machine
ruby -r securerandom -e "puts SecureRandom.alphanumeric(32)"
# Example output: xK8mP2nQ9rL4sT6vW1zY3aB5cD7eF0gH

# Set this as TRUSTED_API_KEYS on Render
```

---

### **Phase 2: Deploy Next.js to Vercel**

1. **Push Next.js code to GitHub**
2. **Connect to Vercel**:
   - Go to vercel.com
   - "Import Git Repository"
   - Select your Next.js repo
   - Click "Deploy"

3. **Set Environment Variables on Vercel:**

```bash
# API endpoint (development - localhost)
NEXT_PUBLIC_API_URL=http://localhost:3001/api/v1

# API endpoint (production - Render)
NEXT_PUBLIC_API_URL=https://api.reporeconnoiter.com/v1

# Server-side API key (never exposed to browser)
API_KEY=<same-as-TRUSTED_API_KEYS-from-Render>
```

**Important**:
- `NEXT_PUBLIC_*` vars are exposed to browser (use for public URLs only)
- `API_KEY` (no prefix) is server-side only (safe for secrets)

4. **Note your Vercel deployment URL**: `your-app.vercel.app`

---

### **Phase 3: Configure Route 53 DNS**

Go to AWS Route 53 → Hosted Zones → `reporeconnoiter.com`

**Create Records:**

#### **A. Main Domain → Vercel**

```
Type: A
Name: reporeconnoiter.com (or @)
Value: <Vercel IP addresses - see below>
TTL: 300
```

**Get Vercel IPs:**
Vercel uses these IPs (as of 2025):
```
76.76.21.21
76.76.21.142
```

Or add CNAME instead:
```
Type: CNAME
Name: reporeconnoiter.com
Value: cname.vercel-dns.com
TTL: 300
```

#### **B. API Subdomain → Render**

```
Type: CNAME
Name: api.reporeconnoiter.com
Value: your-app.onrender.com
TTL: 300
```

#### **C. WWW Redirect (Optional)**

```
Type: CNAME
Name: www.reporeconnoiter.com
Value: cname.vercel-dns.com
TTL: 300
```

**Wait 5-10 minutes** for DNS propagation.

**Test:**
```bash
# Test DNS resolution
dig reporeconnoiter.com
dig api.reporeconnoiter.com

# Test API endpoint
curl https://api.reporeconnoiter.com/v1
```

---

### **Phase 4: Update Vercel Custom Domain**

1. Go to Vercel Dashboard → Your Project → Settings → Domains
2. Add custom domain: `reporeconnoiter.com`
3. Vercel will verify DNS records
4. Add `www.reporeconnoiter.com` (optional)
5. Vercel auto-provisions SSL (Let's Encrypt)

**Wait ~5 minutes** for SSL to activate.

---

### **Phase 5: Update Render Custom Domain**

1. Go to Render Dashboard → Your App → Settings
2. Add custom domain: `api.reporeconnoiter.com`
3. Verify DNS CNAME points to your Render app
4. Render auto-provisions SSL (Let's Encrypt)

**Wait ~5 minutes** for SSL to activate.

---

### **Phase 6: Test End-to-End**

```bash
# Test API directly
curl https://api.reporeconnoiter.com/v1
# Should return: {"version":"v1","endpoints":{...}}

# Test API with Next.js server API key (simulates SSR)
curl -H "Authorization: Bearer <your-api-key>" \
  https://api.reporeconnoiter.com/v1/comparisons
# Should bypass rate limits

# Test public access (rate limited)
curl https://api.reporeconnoiter.com/v1/comparisons
# Should work but count toward rate limit

# Test frontend
curl https://reporeconnoiter.com
# Should return Next.js HTML
```

---

### **Phase 7: Add Cloudflare (Optional but Recommended)**

**Why?** DDoS protection, WAF, bot filtering, global CDN.

#### **A. Sign Up for Cloudflare**

1. Go to cloudflare.com
2. Create free account
3. Add site: `reporeconnoiter.com`
4. Cloudflare scans existing DNS records

#### **B. Review DNS Records**

Cloudflare auto-imports from Route 53. Verify:

```
Type   Name                     Value                      Proxy
A      reporeconnoiter.com      <Vercel IP>                ✅ Proxied
CNAME  api                      your-app.onrender.com      ✅ Proxied
CNAME  www                      cname.vercel-dns.com       ✅ Proxied
```

**Proxied (orange cloud)** = Traffic goes through Cloudflare for protection

#### **C. Update Nameservers in Route 53**

Cloudflare gives you nameservers:
```
ns1.cloudflare.com
ns2.cloudflare.com
```

**In Route 53:**
1. Go to Registered Domains → reporeconnoiter.com
2. Edit nameservers
3. Replace with Cloudflare nameservers
4. Save (propagation: 5 min - 24 hours, usually ~5 min)

**Important**: This does NOT transfer domain ownership, just DNS management.

#### **D. Configure Cloudflare Settings**

**SSL/TLS:**
- Mode: "Full (strict)" (encrypts Cloudflare ↔ Origin)

**Security:**
- Security Level: "Medium"
- Bot Fight Mode: "On"
- Challenge Passage: 30 minutes

**Speed:**
- Auto Minify: Enable JS, CSS, HTML
- Brotli: On

**Firewall (Optional):**
- Create rule: Block countries you don't serve
- Create rule: Challenge traffic on `/admin/*` paths

#### **E. Test with Cloudflare**

```bash
# Check DNS resolves to Cloudflare
dig reporeconnoiter.com
# Should show Cloudflare IPs (104.x.x.x or 172.x.x.x)

# Test API
curl https://api.reporeconnoiter.com/v1
# Should work, now protected by Cloudflare

# Test frontend
curl https://reporeconnoiter.com
# Should work
```

---

## 🔐 Next.js API Integration

### **Server-Side API Calls (SSR/ISR)**

Use the API key to bypass rate limits:

```typescript
// app/api/comparisons/route.ts (Next.js API route)
export async function GET() {
  const response = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL}/comparisons`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.API_KEY}`, // Server-side only
      },
    }
  );

  const data = await response.json();
  return Response.json(data);
}
```

```typescript
// app/page.tsx (Server Component)
async function HomePage() {
  // This runs on Next.js server, not browser
  const response = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL}/comparisons`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.API_KEY}`,
      },
      next: { revalidate: 3600 }, // ISR: revalidate every hour
    }
  );

  const data = await response.json();

  return <ComparisonsList data={data} />;
}
```

### **Client-Side API Calls (Browser)**

**Do NOT use API key** (would expose it). Let rate limits apply:

```typescript
// components/ComparisonsList.tsx (Client Component)
'use client';

export function ComparisonsList() {
  const [comparisons, setComparisons] = useState([]);

  useEffect(() => {
    // No Authorization header - public access
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/comparisons`)
      .then(res => res.json())
      .then(data => setComparisons(data));
  }, []);

  return <div>{/* render comparisons */}</div>;
}
```

### **Best Practice: Proxy Through Next.js API**

This hides the API key from browser:

```typescript
// app/api/comparisons/route.ts
export async function GET() {
  const response = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL}/comparisons`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.API_KEY}`,
      },
    }
  );

  return Response.json(await response.json());
}
```

```typescript
// components/ComparisonsList.tsx
'use client';

export function ComparisonsList() {
  useEffect(() => {
    // Calls Next.js API route, not Rails directly
    fetch('/api/comparisons')
      .then(res => res.json())
      .then(data => setComparisons(data));
  }, []);
}
```

**Benefits:**
- API key stays server-side
- Single source of truth for API calls
- Can add caching, transformation, etc.

---

## 🧪 Testing Checklist

Before going live:

- [ ] Rails API accessible at `https://api.reporeconnoiter.com`
- [ ] Next.js app accessible at `https://reporeconnoiter.com`
- [ ] SSL certificates valid (no browser warnings)
- [ ] CORS allows Next.js domain
- [ ] API key bypasses rate limits (test with curl)
- [ ] Public access works but is rate-limited
- [ ] OAuth login works on production domain
- [ ] Admin dashboard accessible
- [ ] Cloudflare dashboard shows traffic (if enabled)
- [ ] Security headers present: `curl -I https://reporeconnoiter.com`
- [ ] Test rate limiting: Make 101 requests, should get 429

---

## 🚨 Common Issues

### **Issue: CORS errors in browser**

**Solution**: Update `config/initializers/cors.rb` on Render:
```ruby
origins ENV.fetch("NEXTJS_DOMAIN", "https://reporeconnoiter.com")
```

Set Render env var:
```bash
NEXTJS_DOMAIN=https://reporeconnoiter.com
```

### **Issue: SSL certificate errors**

**Wait**: Vercel/Render take 5-10 minutes to provision SSL after DNS setup.

**Check**: DNS CNAME must point to provider's domain (not IP).

### **Issue: "Too many redirects"**

**Cloudflare**: Set SSL mode to "Full (strict)", not "Flexible"

### **Issue: Rate limiting Next.js SSR**

**Check**: `TRUSTED_API_KEYS` env var matches on both Render and Vercel

**Test**:
```bash
curl -H "Authorization: Bearer <key>" https://api.reporeconnoiter.com/v1/comparisons
```

### **Issue: 403 Forbidden from Cloudflare**

**Temporarily disable**: Cloudflare → Firewall → Pause all rules

**Check**: Security level not set to "I'm Under Attack"

---

## 📊 Monitoring

Once live, monitor:

1. **Vercel Analytics**: Request volume, errors, performance
2. **Render Metrics**: CPU, memory, response times
3. **Cloudflare Analytics** (if enabled): Traffic, threats blocked, bandwidth
4. **Sentry**: Application errors, performance issues
5. **Rails Logs**: `heroku logs --tail` equivalent on Render

---

## 🎉 You're Live!

Your architecture:

```
┌──────────────────────────────────────────────┐
│ User visits reporeconnoiter.com              │
└──────────────────┬───────────────────────────┘
                   │
         ┌─────────▼─────────┐
         │   Route 53 DNS    │
         └─────────┬─────────┘
                   │
         ┌─────────▼──────────┐
         │  Cloudflare (opt)  │ ← DDoS, WAF, CDN
         └─────────┬──────────┘
                   │
        ┌──────────▼───────────┐
        │                      │
   ┌────▼─────┐        ┌──────▼──────┐
   │  Vercel  │        │   Render    │
   │ Next.js  │◄───────┤  Rails API  │
   │   SSR    │  API   │  + Postgres │
   └──────────┘  Key   └─────────────┘
```

**Total Monthly Cost:**
- Vercel: Free (Hobby plan)
- Render: $14/month (Starter)
- Route 53: ~$1/month (DNS hosting + queries)
- Cloudflare: Free
- **Total: ~$15/month**

**Next Steps:**
1. Deploy Next.js to Vercel
2. Configure DNS in Route 53
3. Test end-to-end
4. (Optional) Add Cloudflare for extra protection
5. Monitor and iterate!
