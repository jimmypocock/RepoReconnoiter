# Rate Limiting Architecture

**Goal**: Prevent cost explosion from bad actors creating thousands of expensive AI comparisons.

**Two-Layer Defense**:

1. **Application Layer** - Business logic enforced in controllers
2. **Middleware Layer** - Rack::Attack HTTP-level throttling

---

## Layer 1: Application-Level Rate Limiting

**Implementation**: `app/models/user.rb` + `app/controllers/comparisons_controller.rb`

### User Model Methods

```ruby
# Check if user can create another comparison
def can_create_comparison?
  return true if admin?
  comparisons.where("created_at > ?", 24.hours.ago).count < daily_comparison_limit
end

# Daily limit (currently 20/day)
def daily_comparison_limit
  20 # All users get 20/day for now
end

# Remaining comparisons today
def remaining_comparisons_today
  limit = daily_comparison_limit
  used = comparisons.where("created_at > ?", 24.hours.ago).count
  [limit - used, 0].max
end
```

### Controller Integration

```ruby
class ComparisonsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :check_rate_limit, only: [:create]

  private

  def check_rate_limit
    return if current_user.can_create_comparison?

    redirect_to root_path,
      alert: "You've reached your daily limit of #{current_user.daily_comparison_limit} comparisons. Try again tomorrow!"
  end
end
```

### Test Coverage

**File**: `test/models/user_test.rb`

✅ Tests cover:

- Returns true when under daily limit
- Returns false when at daily limit (20)
- Resets after 24 hours
- Admins bypass limit (unlimited)

---

## Layer 2: Middleware-Level Rate Limiting (Rack::Attack)

**Implementation**: `config/initializers/rack_attack.rb`

### Throttle Rules

**1. Per-User Throttling (25/day)**

- Tracks authenticated users by user ID
- Limit: 25 requests per 24 hours (buffer over 20/day business logic)
- Admins exempt from throttling
- Response: 429 with "You've reached your daily limit"

```ruby
throttle("comparisons/user", limit: 25, period: 24.hours) do |req|
  if req.path == "/comparisons" && req.post?
    user = req.env["warden"]&.user
    user&.id unless user&.admin?
  end
end
```

**2. Per-IP Throttling (5/day)**

- Tracks by IP address (anonymous/malicious actors)
- Limit: 5 requests per 24 hours
- No exemptions
- Response: 429 with "Too many requests"

```ruby
throttle("comparisons/ip", limit: 5, period: 24.hours) do |req|
  if req.path == "/comparisons" && req.post?
    req.ip
  end
end
```

**3. OAuth Throttling (10 per 5 minutes)**

- Prevents brute force on GitHub OAuth callback
- Limit: 10 requests per 5 minutes per IP
- Response: 429 with "Rate limit exceeded"

```ruby
throttle("oauth/ip", limit: 10, period: 5.minutes) do |req|
  if req.path.include?("/users/auth/github") && req.post?
    req.ip
  end
end
```

### Safelist

**Localhost in Development**

- Local development exempt from throttling
- Production: No safelist, all requests throttled

```ruby
safelist("allow-localhost") do |req|
  req.ip == "127.0.0.1" || req.ip == "::1" if Rails.env.development?
end
```

### Custom Responses

Returns proper HTTP 429 with:

- **Retry-After header**: Seconds until rate limit resets
- **Custom messages**: User-friendly error messages
- **Content-Type**: text/html

---

## Why Two Layers?

**Application Layer (first line of defense)**:

- Business logic: "This user has created 20 comparisons today"
- Provides user-friendly UI feedback
- Tracked in database (accurate, persistent)
- Tested in unit/integration tests ✅

**Middleware Layer (second line of defense)**:

- HTTP-level protection: "This IP is making too many requests"
- Catches attempts to bypass application logic
- Protects against unauthenticated spam (IP throttling)
- Catches edge cases (race conditions, etc.)

**Example Attack Scenarios**:

1. **Bypassed Authentication**
   - Attacker finds way to skip `authenticate_user!`
   - Application layer fails (no current_user)
   - ✅ Middleware layer catches: IP throttle (5/day)

2. **Rapid-Fire Requests**
   - Attacker sends 50 requests in 1 second
   - Some might slip through application checks (race condition)
   - ✅ Middleware layer catches: User throttle (25/day)

3. **IP Rotation**
   - Attacker rotates IPs to bypass IP throttle
   - But uses same authenticated account
   - ✅ Application layer catches: User limit (20/day)
   - ✅ Middleware layer catches: User throttle (25/day)

---

## Testing Strategy

### Current Testing (API Prep Phase)

**Application-Level Rate Limiting** ✅

- **File**: `test/models/user_test.rb`
- **Coverage**:
  - User can create comparisons when under limit
  - User cannot create comparisons at limit
  - Rate limit resets after 24 hours
  - Admins bypass rate limits

**Middleware-Level Rate Limiting** ⏸️ Deferred

- Rack::Attack disabled in test environment (intentional)
- Will be tested during API integration testing phase

### Future Testing (API Phase)

**When**: Building Next.js frontend + Rails API

**How**: Real HTTP requests to API endpoints

**Test Scenarios**:

```bash
# 1. User throttle (25/day)
for i in {1..26}; do
  curl -X POST https://api.example.com/api/v1/comparisons \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"query": "test"}'
done
# Expected: First 25 succeed (200), 26th fails (429)

# 2. IP throttle (5/day)
for i in {1..6}; do
  curl -X POST https://api.example.com/api/v1/comparisons \
    -d '{"query": "test"}'
done
# Expected: First 5 fail auth (401), 6th fails rate limit (429)

# 3. Admin bypass
for i in {1..30}; do
  curl -X POST https://api.example.com/api/v1/comparisons \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d '{"query": "test"}'
done
# Expected: All 30 succeed (200)

# 4. Retry-After header
curl -i -X POST https://api.example.com/api/v1/comparisons \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query": "test"}'
# Expected (after hitting limit):
# HTTP/1.1 429 Too Many Requests
# Retry-After: 86400
```

**Integration Test Checklist** (for API phase):

- [ ] User throttle enforced (25/day per user)
- [ ] IP throttle enforced (5/day per IP)
- [ ] OAuth throttle enforced (10 per 5 minutes)
- [ ] Admin bypass works (unlimited requests)
- [ ] Rate limit is per-user, not global
- [ ] Multiple users have independent limits
- [ ] Retry-After header included in 429 responses
- [ ] Helpful error messages returned
- [ ] Rate limits reset after period expires
- [ ] Localhost safelist works in development (optional)

---

## Configuration

### Environment Variables

No environment variables needed - all configuration in `config/initializers/rack_attack.rb`.

### Cache Store

Rack::Attack uses Rails cache store:

- **Development**: MemoryStore (fast, local)
- **Production**: Solid Cache (PostgreSQL, persistent)

```ruby
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
```

### Monitoring

**View rate limit status**:

```ruby
# In Rails console
user = User.find(123)
user.remaining_comparisons_today  # => 15
user.can_create_comparison?        # => true
```

**Check Rack::Attack cache** (development):

```ruby
Rack::Attack.cache.store.read("rack::attack:123:comparisons/user")
# => count of requests in current period
```

---

## Cost Impact

**Without Rate Limiting**:

- Bad actor creates 1000 comparisons in 1 hour
- Cost: 1000 × $0.05 = **$50/hour** = **$1200/day**
- Monthly damage: **$36,000**

**With Rate Limiting**:

- Bad actor limited to 25 comparisons/day
- Cost: 25 × $0.05 = **$1.25/day**
- Monthly damage: **$37.50**

**Savings**: 99.9% reduction in potential abuse cost

---

## Security Notes

### Fail-Closed Design

- Empty/nil admin IDs → deny all (no admins)
- Unknown user → apply rate limit
- Cache failure → allow request (don't break app)

### Attack Vectors Covered

✅ **Credential stuffing**: OAuth throttle (10 per 5 min)
✅ **Comparison spam**: User throttle (25/day) + IP throttle (5/day)
✅ **Anonymous spam**: IP throttle (5/day)
✅ **Distributed attack**: User throttle tracks by account
✅ **IP rotation**: User-level throttle persists across IPs

### Attack Vectors NOT Covered

❌ **DDoS**: Rack::Attack helps but not designed for volumetric attacks
❌ **Slowloris**: Use web server (nginx) rate limiting
❌ **Layer 4 attacks**: Use CDN/firewall (Cloudflare, AWS WAF)

---

## Adjusting Limits

**To change limits**, edit `config/initializers/rack_attack.rb`:

```ruby
# Increase user limit to 50/day
throttle("comparisons/user", limit: 50, period: 24.hours) do |req|
  # ...
end

# Decrease IP limit to 3/day
throttle("comparisons/ip", limit: 3, period: 24.hours) do |req|
  # ...
end
```

**Remember**: Also update application-level limit in `User#daily_comparison_limit`.

---

## References

- Rack::Attack docs: <https://github.com/rack/rack-attack>
- OWASP Rate Limiting: <https://owasp.org/www-community/controls/Rate_Limiting>
- Rails Security Guide: <https://guides.rubyonrails.org/security.html>
