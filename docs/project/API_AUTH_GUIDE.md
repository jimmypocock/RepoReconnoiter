# API Authentication Guide for Next.js

## 🔑 Three-Tier Access Model

```
┌─────────────────────────────────────────────────────┐
│ Tier 1: Public Access (Rate Limited)               │
│ - Anyone can read                                   │
│ - 100 requests/hour per IP                          │
│ - 20 requests/10min burst                           │
└─────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────┐
│ Tier 2: Trusted Client (API Key)                   │
│ - Next.js server (SSR/ISR)                          │
│ - Bypasses rate limits                              │
│ - Server-side only (never exposed to browser)       │
│ - Database-backed with BCrypt encryption            │
└─────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────┐
│ Tier 3: Authenticated Users (OAuth)                │
│ - GitHub OAuth login                                │
│ - Can create comparisons                            │
│ - Session-based (cookies)                           │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Setup Instructions

### **1. Get API Key from Rails Backend**

API keys are managed in the Rails database (not ENV vars in production).

**For Development:**
Contact the Rails backend developer to generate a development key:
```bash
# They'll run this on their local machine
bin/rails api_keys:generate NAME="Next.js Development (Local)"

# Output will include a 64-character hex key:
# 🔑 API Key: 266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a
```

**For Production:**
The key must be generated on the production Rails server (Render):
```bash
# Rails developer runs this on Render shell
bin/rails api_keys:generate NAME="Next.js Production (Vercel)"

# Output: 64-character hex key (shown only once!)
```

### **2. Set on Vercel (Next.js Frontend)**

Go to Vercel Dashboard → Settings → Environment Variables:

```bash
# Server-side API key (never exposed to browser)
API_KEY=266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a

# Public API URL (exposed to browser)
NEXT_PUBLIC_API_URL=https://api.reporeconnoiter.com/v1
```

**Important**:
- `API_KEY` (no `NEXT_PUBLIC_` prefix) = Server-side only ✅
- `NEXT_PUBLIC_API_URL` = Exposed to browser ✅
- Production uses database-backed keys (ENV fallback disabled for security)

---

## 💻 Next.js Usage Examples

### **Server-Side Rendering (SSR)**

```typescript
// app/comparisons/page.tsx
export default async function ComparisonsPage() {
  // This runs on Next.js server, not in browser
  const response = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL}/comparisons`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.API_KEY}`, // Server-side only
      },
      next: { revalidate: 3600 }, // ISR: revalidate every hour
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch comparisons');
  }

  const data = await response.json();

  return <div>{/* Render comparisons */}</div>;
}
```

### **Next.js API Route (Recommended Pattern)**

```typescript
// app/api/comparisons/route.ts
export async function GET(request: Request) {
  const response = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL}/comparisons`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.API_KEY}`,
      },
    }
  );

  if (!response.ok) {
    return Response.json(
      { error: 'Failed to fetch comparisons' },
      { status: response.status }
    );
  }

  const data = await response.json();
  return Response.json(data);
}
```

Then in your client component:

```typescript
// components/ComparisonsList.tsx
'use client';

export function ComparisonsList() {
  const [comparisons, setComparisons] = useState([]);

  useEffect(() => {
    // Call Next.js API route (not Rails directly)
    // API key stays server-side
    fetch('/api/comparisons')
      .then(res => res.json())
      .then(data => setComparisons(data.data))
      .catch(err => console.error(err));
  }, []);

  return <div>{/* Render */}</div>;
}
```

### **Client-Side Fetching (Public Access)**

```typescript
// components/PublicComparisons.tsx
'use client';

export function PublicComparisons() {
  useEffect(() => {
    // NO Authorization header - uses public access
    // Subject to rate limits (100/hour)
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/comparisons`)
      .then(res => {
        if (res.status === 429) {
          // Rate limited
          console.error('Rate limit exceeded');
          return;
        }
        return res.json();
      })
      .then(data => console.log(data));
  }, []);
}
```

### **Server Action (App Router)**

```typescript
// app/actions/comparisons.ts
'use server';

export async function getComparisons() {
  const response = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL}/comparisons`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.API_KEY}`,
      },
      cache: 'no-store', // or 'force-cache' for caching
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch');
  }

  return response.json();
}
```

```typescript
// app/comparisons/page.tsx
import { getComparisons } from '../actions/comparisons';

export default async function Page() {
  const data = await getComparisons();
  return <div>{/* Render */}</div>;
}
```

---

## 🧪 Testing

### **Test Public Access (No Auth)**

```bash
# Should work but count toward rate limit
curl https://api.reporeconnoiter.com/v1/comparisons

# Make 101 requests to trigger rate limit
for i in {1..101}; do
  curl -s https://api.reporeconnoiter.com/v1/comparisons > /dev/null
  echo "Request $i"
done

# Should get 429 after 100 requests
```

### **Test Trusted Client (With API Key)**

```bash
# Should bypass rate limits
curl -H "Authorization: Bearer xK8mP2nQ9rL4sT6vW1zY3aB5cD7eF0gH" \
  https://api.reporeconnoiter.com/v1/comparisons

# Make 200 requests - should all succeed
for i in {1..200}; do
  curl -s -H "Authorization: Bearer YOUR_API_KEY" \
    https://api.reporeconnoiter.com/v1/comparisons > /dev/null
  echo "Request $i"
done
```

### **Test Invalid API Key**

```bash
# Should still apply rate limits (not bypass)
curl -H "Authorization: Bearer invalid-key-12345" \
  https://api.reporeconnoiter.com/v1/comparisons
```

---

## 🔒 Security Best Practices

### **DO:**

✅ **Store API key in environment variables**
```typescript
process.env.API_KEY // ✅ Server-side
```

✅ **Use API key in server-side code only**
```typescript
// Server Component, API Route, Server Action
headers: { 'Authorization': `Bearer ${process.env.API_KEY}` }
```

✅ **Proxy client requests through Next.js API routes**
```typescript
// Client → Next.js API → Rails API
fetch('/api/comparisons') // Client calls Next.js
```

✅ **Rotate API keys periodically** (every 90 days)

✅ **Use different keys for dev/staging/production**

### **DON'T:**

❌ **Never expose API key in browser**
```typescript
// DON'T DO THIS
const API_KEY = 'xK8mP2nQ9rL4sT6vW1zY3aB5cD7eF0gH'; // ❌ EXPOSED!
```

❌ **Don't use NEXT_PUBLIC_ prefix for secrets**
```bash
# ❌ BAD - Exposed to browser
NEXT_PUBLIC_API_KEY=secret

# ✅ GOOD - Server-side only
API_KEY=secret
```

❌ **Don't commit API keys to git**
```bash
# ❌ Never do this
git add .env
```

❌ **Don't log API keys**
```typescript
console.log(process.env.API_KEY); // ❌ Don't log secrets
```

---

## 🚨 Rate Limit Responses

### **Success (Within Limits)**

```json
{
  "data": [
    {
      "id": 1,
      "user_query": "Rails background job library",
      ...
    }
  ],
  "meta": {
    "pagination": {...}
  }
}
```

### **Rate Limited (429)**

```json
{
  "error": {
    "message": "API rate limit exceeded. Try again later.",
    "retry_after": 3456
  }
}
```

Headers:
```
HTTP/1.1 429 Too Many Requests
Retry-After: 3456
Content-Type: application/json
```

### **Handling in Next.js**

```typescript
const response = await fetch('/api/comparisons');

if (response.status === 429) {
  const data = await response.json();
  const retryAfter = data.error.retry_after;

  console.error(`Rate limited. Retry in ${retryAfter} seconds`);

  // Show error to user
  return { error: 'Too many requests. Please try again later.' };
}
```

---

## 📊 Monitoring

### **Check Rate Limit Status**

Rails doesn't expose rate limit headers by default, but you can check logs:

```bash
# On Render
heroku logs --tail

# Look for Rack::Attack messages
[Rack::Attack] Throttle api/ip: 123.45.67.89
```

### **Monitor API Usage**

```sql
-- Check comparisons created today
SELECT COUNT(*) FROM comparisons
WHERE created_at >= CURRENT_DATE;

-- Check by user
SELECT user_id, COUNT(*)
FROM comparisons
WHERE created_at >= CURRENT_DATE
GROUP BY user_id
ORDER BY COUNT(*) DESC;
```

---

## 🔄 Rotating API Keys

When you need to rotate keys (security breach, periodic rotation - recommended every 90 days):

### **1. Request New Key from Rails Developer**

```bash
# Rails developer runs on production (Render shell)
bin/rails api_keys:generate NAME="Next.js Production (Vercel) v2"

# Output: new64CharacterHexKey...
```

### **2. Update Vercel**

```bash
# Update API_KEY environment variable with new key
API_KEY=new64CharacterHexKey...
```

Deploy Next.js to activate new key.

### **3. Verify New Key Works**

Test a few requests to ensure the new key is working in production.

### **4. Revoke Old Key**

Once Next.js is deployed and verified:

```bash
# Rails developer runs on production
bin/rails api_keys:revoke ID=<old_key_id>

# Check with: bin/rails api_keys:list
```

**Note**: The old key continues working until explicitly revoked, allowing zero-downtime rotation.

---

## 📚 Additional Resources

- [Next.js Environment Variables](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables)
- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)
- [Render Environment Variables](https://render.com/docs/environment-variables)
- [Rack::Attack Documentation](https://github.com/rack/rack-attack)

---

## ✅ Quick Checklist

Before going live:

- [ ] Request production API key from Rails developer (64-character hex)
- [ ] Set `API_KEY` on Vercel (no `NEXT_PUBLIC_` prefix!)
- [ ] Set `NEXT_PUBLIC_API_URL=https://api.reporeconnoiter.com/v1` on Vercel
- [ ] Test API key bypasses rate limits (make 200+ requests)
- [ ] Test public access still rate-limited (gets 429 after 100 requests)
- [ ] Verify key not exposed in browser (check Network tab DevTools)
- [ ] Set up key rotation reminder (90 days)
- [ ] Document key location (password manager)

## 🔐 API Key Details

**Format**: 64-character hexadecimal string (256-bit entropy)
```
266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a
```

**Storage**:
- Rails backend: BCrypt hash in database (irreversible encryption)
- Next.js: Server-side environment variable only (never in browser)

**Security**:
- Production keys ONLY exist in database (no ENV var fallback)
- Development keys can use ENV fallback for convenience
- Each environment should have separate keys
