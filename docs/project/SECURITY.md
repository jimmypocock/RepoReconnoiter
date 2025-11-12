# Security Configuration

This document outlines the security measures in place for RepoReconnoiter's API and web application.

## 🛡️ Application-Level Security (Implemented)

### 1. **Rate Limiting (Rack::Attack)**

#### API Endpoints
- **General API**: 100 requests/hour per IP
- **Burst Protection**: 20 requests/10 minutes for unauthenticated users
- **Returns**: HTTP 429 with `Retry-After` header and JSON error

#### User Actions
- **Comparison Creation**: 25/day per authenticated user, 5/day per IP
- **OAuth Login**: 10 attempts per 5 minutes per IP

#### IP Blocklist
- **Environment Variable**: `BLOCKED_IPS="1.2.3.4,5.6.7.8"` (comma-separated)
- **Response**: HTTP 403 Forbidden

#### Cache Backend
- **Development**: Rails.cache (Solid Cache)
- **Production**: Solid Cache (persistent, shared across servers)
- **Note**: Previous MemoryStore configuration would NOT work with multiple servers

### 2. **Request Size Limits**

- **Max Request Size**: 10MB (configurable via `MAX_REQUEST_SIZE` env var)
- **Protection**: Prevents massive payload attacks
- **Configured in**: `config/puma.rb`

### 3. **CORS Protection**

- **Development Origins**:
  - `http://localhost:3000`
  - `http://localhost:3001`
  - `http://localhost:4000`
  - `http://localhost:5173` (Vite)
  - `http://127.0.0.1:3000`
  - `http://127.0.0.1:3001`

- **Production**: Set `NEXTJS_DOMAIN` env var (e.g., `https://reporeconnoiter.com`)
- **Credentials**: Disabled (stateless API)
- **Methods**: GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD

### 4. **Input Validation**

- **Strong Parameters**: All controller params are explicitly permitted
- **Per-Page Limits**: Capped at 100 items (prevents huge database queries)
- **SQL Injection**: Rails parameterized queries (automatic protection)

### 5. **Authentication**

#### Three-Tier Authentication Model:

**Tier 1: Public Read Access (Rate Limited)**
- **Endpoints**: GET /api/v1/comparisons, GET /api/v1
- **Access**: Anyone, no authentication required
- **Limits**: 100 requests/hour, 20/10min burst
- **Use Case**: Public sharing, SEO, discoverability

**Tier 2: Trusted Client Access (API Key)**
- **Client**: Next.js server on Vercel (SSR/ISR requests)
- **Authentication**: Bearer token in Authorization header
- **Limits**: Bypasses rate limits (trusted client)
- **Setup**: Set `TRUSTED_API_KEYS` env var on Render
- **Security**: API key never exposed to browser (server-side only)

**Tier 3: User Authentication (OAuth)**
- **Method**: Devise + GitHub OAuth (invite-only whitelist)
- **Access**: Create comparisons, profile, admin features
- **Session**: Cookie-based, works across reporeconnoiter.com domain
- **Admin**: Restricted by `ALLOWED_ADMIN_GITHUB_IDS` env var

### 6. **Security Headers**

All configured in `config/application.rb`:

- **X-Frame-Options**: DENY (clickjacking prevention)
- **X-Content-Type-Options**: nosniff (MIME sniffing prevention)
- **X-XSS-Protection**: 1; mode=block
- **Referrer-Policy**: strict-origin-when-cross-origin
- **Permissions-Policy**: Disables geolocation, camera, microphone, payment APIs
- **Content-Security-Policy**: Strict CSP with nonce-based inline scripts
- **HSTS** (production only): max-age=31536000; includeSubDomains

### 7. **Error Tracking**

- **Service**: Sentry
- **Coverage**: Automatic exception tracking, performance monitoring
- **Privacy**: Stack traces sanitized (no user data)

### 8. **Prompt Injection Prevention**

- **Protection**: Multi-layered input sanitization in `Prompter` service
- **Coverage**: 15+ patterns for credential extraction, system info leaks
- **Applied**: All user inputs before AI processing

---

## 🌐 Infrastructure-Level Security (Recommended)

### 1. **CDN/DDoS Protection (CRITICAL)**

**Recommended: Cloudflare Free Plan**

Benefits:
- DDoS protection (Layer 3, 4, 7)
- WAF (Web Application Firewall)
- Bot protection
- Automatic SSL/TLS
- Global CDN (reduce latency)
- Rate limiting (in addition to Rack::Attack)

**Setup**:
1. Sign up at cloudflare.com
2. Add domain: `reporeconnoiter.com`
3. Update nameservers at domain registrar
4. Enable "Under Attack" mode if needed
5. Configure DNS:
   - `A` record: `reporeconnoiter.com` → Render IP
   - `CNAME` record: `api.reporeconnoiter.com` → Render app URL

**Cost**: Free (or $20/month Pro for advanced DDoS)

### 2. **Render.com Built-in Security**

Render provides:
- **DDoS Protection**: Basic Layer 3/4 protection
- **SSL/TLS**: Automatic Let's Encrypt certificates
- **Firewall**: Port restrictions (only 443/80 exposed)
- **Health Checks**: Auto-restart on failures

**Note**: Render's DDoS protection is basic. For production, use Cloudflare in front.

### 3. **Database Security**

PostgreSQL on Render:
- **Encryption**: At-rest encryption (automatic)
- **SSL**: Enforced for all connections
- **Access**: Restricted to Render internal network only
- **Backups**: Daily automatic backups (7-day retention)

### 4. **Environment Variables**

**Critical Secrets** (set in Render dashboard):
- `SECRET_KEY_BASE` - Rails encryption key
- `RAILS_MASTER_KEY` - Credentials decryption
- `OPENAI_ACCESS_TOKEN` - OpenAI API key
- `GITHUB_CLIENT_SECRET` - OAuth secret

**Never commit**:
- `.env` (in `.gitignore`)
- `config/master.key` (in `.gitignore`)
- Any API keys or secrets

---

## 🚨 Incident Response

### When You Detect Abuse:

#### 1. **Block IP Address**
```bash
# On Render, set environment variable:
BLOCKED_IPS="1.2.3.4,5.6.7.8"

# Restart app to apply
```

#### 2. **Check Sentry**
- Review error patterns
- Identify suspicious requests
- Look for 429 (rate limit) spikes

#### 3. **Adjust Rate Limits**
Edit `config/initializers/rack_attack.rb`:
```ruby
# Lower limit temporarily
throttle("api/ip", limit: 50, period: 1.hour) do |req|
  # ...
end
```

#### 4. **Enable Cloudflare "Under Attack" Mode**
- Adds JavaScript challenge before accessing site
- Blocks bots automatically

#### 5. **Monitor Costs**
- Check `ai_costs` table for unusual spikes
- OpenAI usage should stay under $10/month

---

## 📊 Monitoring

### What to Monitor:

1. **Request Volume**: Track `/api/v1/comparisons` hits
2. **429 Errors**: Rate limit triggers (indicates abuse attempts)
3. **Response Times**: Slow queries might indicate attack
4. **Error Rate**: Spikes in 500 errors
5. **AI Costs**: Daily spending in `ai_costs` table
6. **Database Connections**: Should stay under 97 (Render limit)

### Tools:

- **Sentry**: Error tracking, performance monitoring
- **Render Metrics**: CPU, memory, response times
- **Rails Logs**: `bin/rails log:tail` (production)
- **Cloudflare Analytics**: Traffic patterns, threats blocked

---

## ✅ Pre-Deployment Security Checklist

Before going live:

- [ ] Set `NEXTJS_DOMAIN` to production frontend URL
- [ ] Enable Force SSL in production (already done)
- [ ] Add Cloudflare in front of Render
- [ ] Set up Sentry alerts for error spikes
- [ ] Test rate limiting with curl (simulate abuse)
- [ ] Verify CORS only allows your Next.js domain
- [ ] Check security headers: https://securityheaders.com/
- [ ] Run security scans: `bin/rails ci:security`
- [ ] Set strong `SECRET_KEY_BASE` (run `bin/rails secret`)
- [ ] Whitelist admin GitHub ID in `ALLOWED_ADMIN_GITHUB_IDS`
- [ ] Test API with public tools (Postman, curl) to verify security

---

## 🔐 Security Audit Log

| Date       | Change                          | Reason                        |
|------------|---------------------------------|-------------------------------|
| 2025-11-11 | Added API rate limiting         | Prevent scraping/abuse        |
| 2025-11-11 | Switched Rack::Attack to Rails.cache | Support multiple servers |
| 2025-11-11 | Added request size limits (10MB)| Prevent massive payloads      |
| 2025-11-11 | Added IP blocklist support      | Ban bad actors                |
| 2025-11-11 | JSON error responses for API    | Better client experience      |

---

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Rack::Attack Documentation](https://github.com/rack/rack-attack)
- [Cloudflare DDoS Protection](https://www.cloudflare.com/ddos/)
- [Render Security](https://render.com/docs/security)
