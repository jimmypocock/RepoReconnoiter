# API Key Management System

The API Key system provides database-backed API key authentication with usage tracking, auditing, and key lifecycle management.

## 🎯 Overview

**Problem**: Environment variable API keys don't provide:
- Usage tracking (how many requests?)
- Audit trail (who created what, when?)
- Revocation (without removing the key)
- Multiple keys per client
- Key lifecycle management

**Solution**: Database-backed `ApiKey` model with BCrypt hashing and automatic usage tracking.

---

## 📊 Schema

```ruby
create_table :api_keys do |t|
  t.string :name, null: false                    # Human-readable name
  t.string :key_digest, null: false              # BCrypt hash of the key
  t.datetime :last_used_at                       # Last time key was used
  t.integer :request_count, default: 0           # Total requests with this key
  t.datetime :revoked_at                         # Soft delete (nil = active)
  t.references :user, foreign_key: true          # Optional user association
  t.timestamps
end

# Indexes
add_index :api_keys, :key_digest, unique: true
add_index :api_keys, :revoked_at
add_index :api_keys, [:user_id, :revoked_at]
```

---

## 🔐 Security Model

### **Key Storage (BCrypt Hashing)**

API keys are **never stored in plaintext**. Instead, we hash them with BCrypt (same as passwords):

```ruby
# When generating
raw_key = SecureRandom.hex(32)  # 64-character hex string
key_digest = BCrypt::Password.create(raw_key)

# When authenticating
BCrypt::Password.new(key_digest) == provided_key
```

**Benefits**:
- Even if database is compromised, keys cannot be recovered
- Same battle-tested approach as password storage
- Slow hashing prevents brute force attacks

### **Key Generation**

Keys are 64-character hexadecimal strings (32 bytes):

```
266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a
```

- **Entropy**: 256 bits (cryptographically strong)
- **Format**: Hexadecimal (URL-safe, no special characters)
- **Source**: `SecureRandom.hex(32)` (uses `/dev/urandom`)

---

## 🛠️ Usage

### **Generate a Key**

```bash
# System key (no user)
bin/rails api_keys:generate NAME="Next.js Production"

# User-specific key
bin/rails api_keys:generate NAME="Mobile App" EMAIL="user@example.com"
```

**Output**:
```
✅ API Key Generated Successfully!

Name:       Next.js Production
ID:         2
User:       System (no user)
Created:    2025-11-12 03:55:11 UTC

🔑 API Key: 266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a

⚠️  IMPORTANT: Save this key NOW! It will not be shown again.

To use in Next.js (Vercel env vars):
  API_KEY=266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a

To use in curl:
  curl -H "Authorization: Bearer 266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a" \
    https://api.reporeconnoiter.com/v1/comparisons
```

### **List All Keys**

```bash
bin/rails api_keys:list
```

**Output**:
```
API Keys:

ID    Name                           User                 Requests   Status          Last Used
----------------------------------------------------------------------------------------------------
2     Next.js Production             System               142        Active          2025-11-12 04:23
1     Next.js Development            System               0          Active          Never

Total: 2 keys
Active: 2
Revoked: 0
```

### **Revoke a Key**

```bash
bin/rails api_keys:revoke ID=2
```

**Output**:
```
✅ API Key Revoked Successfully!

Name:      Next.js Production
ID:        2
User:      System
Requests:  142
Revoked:   2025-11-12 04:25:33 UTC
```

### **View Statistics**

```bash
bin/rails api_keys:stats
```

**Output**:
```
API Key Statistics
==================================================

Total Keys:      5
Active:          3
Revoked:         2
Total Requests:  1,427

Most Used Keys (Top 5):

ID    Name                           Requests   Last Used
----------------------------------------------------------------------
3     Next.js Production (v2)        1,285      2025-11-12 04:55
1     Mobile App iOS                 142        2025-11-12 03:12
5     Internal Testing               0          Never
```

### **Cleanup Old Keys**

```bash
bin/rails api_keys:cleanup
```

Deletes revoked keys older than 90 days.

---

## 💻 Programmatic Usage

### **Generate a Key (Ruby)**

```ruby
result = ApiKey.generate(name: "My App", user: current_user)

api_key_record = result[:api_key]  # ApiKey model instance
raw_key = result[:raw_key]         # Plain-text key (show once!)

# Store raw_key securely (password manager, Vercel env, etc.)
# api_key_record.key_digest contains the BCrypt hash
```

### **Authenticate a Key**

```ruby
# In Rack::Attack or middleware
raw_key = request.headers["Authorization"]&.sub("Bearer ", "")
api_key = ApiKey.authenticate(raw_key)

if api_key
  # Valid and active key
  # Track usage asynchronously
  ApiKeyUsageTracker.track_async(api_key.id)
else
  # Invalid or revoked key
end
```

### **Revoke a Key**

```ruby
api_key = ApiKey.find(123)
api_key.revoke!  # Sets revoked_at to current time
```

### **Check if Active**

```ruby
api_key.active?  # true if revoked_at is nil
```

### **Scopes**

```ruby
ApiKey.active              # All non-revoked keys
ApiKey.revoked             # All revoked keys
ApiKey.for_user(user)      # Keys belonging to a user
ApiKey.recent              # Ordered by created_at desc
```

---

## 🔄 Request Flow

### **With API Key (Bypasses Rate Limits)**

```
1. Client sends request with Authorization header
   GET /api/v1/comparisons
   Authorization: Bearer 266eda3d711399ca87ab19dfbebff1ad2430...

2. Rack::Attack intercepts (before routing)
   - Extracts key from header
   - Calls ApiKey.authenticate(raw_key)

3. ApiKey.authenticate checks database
   - Finds all active keys
   - Compares BCrypt hash
   - Returns ApiKey record if valid

4. If valid, Rack::Attack safelists request
   - Bypasses rate limits
   - Queues TrackApiKeyUsageJob

5. Request proceeds normally

6. Background job runs (Solid Queue)
   - Increments request_count
   - Updates last_used_at
```

### **Without API Key (Rate Limited)**

```
1. Client sends request without Authorization header

2. Rack::Attack checks safelist
   - No API key found
   - Falls through to rate limit checks

3. Rate limit applies
   - 100 requests/hour
   - 20 requests/10min burst

4. If over limit: 429 Too Many Requests
```

---

## 🚀 Production Deployment

### **Step 1: Generate Production Key**

On your local machine or Render shell:

```bash
bin/rails api_keys:generate NAME="Next.js Production (Vercel)"
```

**Save the output key** (shown once only!)

### **Step 2: Set on Vercel**

Go to Vercel → Project → Settings → Environment Variables:

```
API_KEY=266eda3d711399ca87ab19dfbebff1ad2430d7b374a50577eea057de1ad0224a
```

Redeploy Next.js to activate.

### **Step 3: Remove ENV Fallback (Optional)**

Once all keys are in database, remove ENV var fallback from `config/initializers/rack_attack.rb`:

```ruby
# Remove this block after migration
trusted_api_keys = ENV.fetch("TRUSTED_API_KEYS", "").split(",").map(&:strip)
trusted_api_keys.include?(raw_key)
```

---

## 📊 Monitoring

### **Database Queries**

```sql
-- Active keys with usage
SELECT id, name, request_count, last_used_at
FROM api_keys
WHERE revoked_at IS NULL
ORDER BY request_count DESC;

-- Keys never used
SELECT id, name, created_at
FROM api_keys
WHERE last_used_at IS NULL
  AND revoked_at IS NULL;

-- Most active keys (last 7 days)
SELECT id, name, request_count
FROM api_keys
WHERE last_used_at >= NOW() - INTERVAL '7 days'
ORDER BY request_count DESC
LIMIT 10;
```

### **Rails Console**

```ruby
# Total requests across all keys
ApiKey.sum(:request_count)

# Most used key
ApiKey.active.order(request_count: :desc).first

# Keys created this month
ApiKey.where('created_at >= ?', 1.month.ago).count

# Usage by user
User.joins(:api_keys).group('users.email').sum('api_keys.request_count')
```

---

## 🔒 Security Considerations

### **✅ Good**

1. **BCrypt hashing** - Keys never stored in plaintext
2. **Secure random generation** - Cryptographically strong keys
3. **Soft delete (revoke)** - Audit trail preserved
4. **Usage tracking** - Know when/how keys are used
5. **Unique constraint** - Prevents duplicate keys
6. **Background tracking** - Doesn't slow down requests

### **⚠️ Limitations**

1. **No automatic rotation** - Must manually rotate keys
2. **No expiration dates** - Keys don't auto-expire (future feature)
3. **No scopes/permissions** - All keys have same access (future feature)
4. **Linear search for auth** - Slower at scale (can optimize with key prefixes)

### **🔮 Future Enhancements**

- [ ] Key expiration (`expires_at` field)
- [ ] Scopes/permissions (`scopes` JSONB field)
- [ ] Rate limit overrides per key (`rate_limit_override` field)
- [ ] Key prefixes for faster lookups (`sk_live_...`, `sk_test_...`)
- [ ] IP whitelisting per key
- [ ] Webhook signing keys
- [ ] Key usage analytics dashboard

---

## 🧪 Testing

### **Generate Test Key**

```bash
NAME="Test Key" bin/rails api_keys:generate
```

### **Test Authentication**

```bash
# Should work (bypass rate limits)
curl -H "Authorization: Bearer <your-key>" \
  http://localhost:3001/api/v1/comparisons

# Should fail (invalid key)
curl -H "Authorization: Bearer invalid-key-123" \
  http://localhost:3001/api/v1/comparisons
```

### **Test Rate Limiting**

```bash
# Make 101 requests without key - should get 429
for i in {1..101}; do
  curl -s http://localhost:3001/api/v1/comparisons > /dev/null
  echo "Request $i"
done
```

### **Check Usage Tracking**

```bash
# Use key a few times
curl -H "Authorization: Bearer <key>" http://localhost:3001/api/v1/comparisons

# Wait for background job (2-3 seconds)
sleep 3

# Check stats
bin/rails api_keys:list
```

---

## 📚 Model Reference

### **Instance Methods**

```ruby
api_key.active?         # => true/false
api_key.revoke!         # Sets revoked_at, returns true
api_key.track_usage!    # Increments count, updates last_used_at
```

### **Class Methods**

```ruby
ApiKey.authenticate(raw_key)           # => ApiKey or nil
ApiKey.generate(name:, user: nil)      # => { api_key:, raw_key: }
```

### **Scopes**

```ruby
ApiKey.active            # WHERE revoked_at IS NULL
ApiKey.revoked           # WHERE revoked_at IS NOT NULL
ApiKey.for_user(user)    # WHERE user_id = ?
ApiKey.recent            # ORDER BY created_at DESC
```

---

## 🔄 Migration from ENV Vars

### **Current State (Hybrid)**

Rack::Attack checks both:
1. Database keys (preferred)
2. ENV var keys (fallback)

### **Migration Steps**

1. Generate database key for each environment:
   ```bash
   bin/rails api_keys:generate NAME="Next.js Production"
   bin/rails api_keys:generate NAME="Next.js Staging"
   ```

2. Update Vercel env vars to use new keys

3. Test in production for 1 week

4. Remove `TRUSTED_API_KEYS` ENV var from Render

5. Remove ENV fallback code from `rack_attack.rb`

---

## ✅ Checklist

**Before going live**:

- [ ] Generate production API key
- [ ] Set `API_KEY` on Vercel (server-side only!)
- [ ] Test authentication works
- [ ] Verify usage tracking (check `bin/rails api_keys:list` after a few requests)
- [ ] Document key in password manager
- [ ] Set up key rotation reminder (90 days)
- [ ] Monitor `api_keys` table size
- [ ] Plan for key expiration feature

---

## 💡 Tips

1. **Name keys descriptively**: "Next.js Production (Vercel)" not "Key 1"
2. **Use separate keys per environment**: Prod, staging, dev
3. **Rotate keys every 90 days**: Security best practice
4. **Monitor unused keys**: Delete or revoke
5. **Track key ownership**: Use `user` association when possible
6. **Keep revoked keys**: Audit trail, don't delete
7. **Use background tracking**: Keeps requests fast

---

## 🆘 Troubleshooting

### **Key not working (401/403)**

```bash
# Check if key exists and is active
bin/rails runner "puts ApiKey.authenticate('your-key-here').inspect"
# Should show ApiKey record, not nil

# Check if key was revoked
bin/rails runner "puts ApiKey.find(123).revoked_at"
# Should be nil if active
```

### **Usage not tracking**

```bash
# Check if background jobs are running
bin/rails runner "puts Solid::Queue::Job.count"

# Start Solid Queue if not running
bin/rails solid_queue:start
```

### **Slow authentication**

With many keys (1000+), authentication slows down (linear search).

**Solution**: Add key prefixes to allow direct lookup:

```ruby
# Future optimization
api_key.update!(key_prefix: "sk_live_abc123")
add_index :api_keys, :key_prefix

# In authenticate:
prefix = raw_key[0..15]  # First 16 chars
ApiKey.active.where(key_prefix: prefix).find_each do |api_key|
  # ... check hash
end
```

---

**For more info**: See `app/models/api_key.rb` and `lib/tasks/api_keys.rake`
