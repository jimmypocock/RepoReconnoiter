# API Prep - Security-First Backend Hardening

**Goal**: Harden backend with security and cost control before exposing as API

**Total Time**: ~6-8 hours (thorough, security-focused)

**Why This Matters**: A single bad actor could cost $100+ in OpenAI bills in minutes. We need bulletproof auth, authorization, and rate limiting.

---

## 🔐 Security Priorities

### Critical Security Risks to Mitigate:

1. **Cost Explosion** 💸
   - Unauthorized comparison creation → $0.05-0.10 per comparison
   - No rate limiting on API → could create 1000s of comparisons
   - Deep analysis costs $0.03-0.05 per repo

2. **Data Leakage** 🔓
   - Users accessing other users' comparisons
   - Non-admins accessing admin endpoints
   - Unauthenticated access to protected resources

3. **Authorization Bypass** 🚨
   - Admin endpoints exposed without proper checks
   - User.admin? logic not tested → might fail
   - Whitelist bypass could allow anyone to create accounts

---

## Phase 1: Authentication & Authorization Tests (HIGH PRIORITY)

**Time**: 2-3 hours
**Why**: These are your security gates - they MUST work

### 1.1: User.admin? Tests (~30 min)

**File**: `test/models/user_test.rb`

**Critical Test Cases**:
```ruby
test "admin? returns true when user GitHub ID is in ALLOWED_ADMIN_GITHUB_IDS" do
  ENV["ALLOWED_ADMIN_GITHUB_IDS"] = "12345,67890"
  user = users(:jimmy)
  user.update!(github_id: "12345")
  assert user.admin?
end

test "admin? returns false when user GitHub ID is not in list" do
  ENV["ALLOWED_ADMIN_GITHUB_IDS"] = "12345,67890"
  user = users(:jimmy)
  user.update!(github_id: "99999")
  refute user.admin?
end

test "admin? returns false when ALLOWED_ADMIN_GITHUB_IDS is empty" do
  ENV["ALLOWED_ADMIN_GITHUB_IDS"] = ""
  user = users(:jimmy)
  refute user.admin? # Fail-closed security
end

test "admin? returns false when ALLOWED_ADMIN_GITHUB_IDS is nil" do
  ENV["ALLOWED_ADMIN_GITHUB_IDS"] = nil
  user = users(:jimmy)
  refute user.admin? # Fail-closed security
end

test "admin? handles whitespace in ALLOWED_ADMIN_GITHUB_IDS" do
  ENV["ALLOWED_ADMIN_GITHUB_IDS"] = " 12345 , 67890 "
  user = users(:jimmy)
  user.update!(github_id: "12345")
  assert user.admin?
end
```

**Why Critical**: If `User.admin?` fails, non-admins could access admin endpoints (whitelist management, stats, cost data).

### 1.2: Whitelist Authorization Tests (~1 hour)

**File**: `test/models/user_test.rb`

**Test OAuth Authorization Flow**:
```ruby
test "User.from_omniauth creates user when whitelisted" do
  WhitelistedUser.create!(github_id: "12345", github_username: "testuser")

  auth = OmniAuth::AuthHash.new({
    provider: "github",
    uid: "12345",
    info: { nickname: "testuser", email: "test@example.com" }
  })

  assert_difference "User.count", 1 do
    user = User.from_omniauth(auth)
    assert_equal "12345", user.github_id
    assert_equal "testuser", user.github_username
  end
end

test "User.from_omniauth raises error when not whitelisted" do
  auth = OmniAuth::AuthHash.new({
    provider: "github",
    uid: "99999",
    info: { nickname: "badactor", email: "bad@example.com" }
  })

  assert_raises(StandardError) do
    User.from_omniauth(auth)
  end
end

test "User.from_omniauth updates existing user info" do
  user = users(:jimmy)
  WhitelistedUser.create!(github_id: user.github_id, github_username: user.github_username)

  auth = OmniAuth::AuthHash.new({
    provider: "github",
    uid: user.github_id,
    info: {
      nickname: "new_username",
      email: "new@example.com",
      image: "https://new-avatar.com/image.jpg"
    }
  })

  updated_user = User.from_omniauth(auth)
  assert_equal "new_username", updated_user.github_username
  assert_equal "new@example.com", updated_user.email
end
```

**Why Critical**: Whitelist is your ONLY gate for API access. If this fails, anyone could create accounts and spam expensive AI calls.

### 1.3: Rate Limiting Tests (~1 hour)

**File**: `test/integration/rate_limiting_test.rb` (create new)

**Test Rack::Attack Configuration**:
```ruby
require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    # Clear Rack::Attack cache before each test
    Rack::Attack.cache.store.clear if Rack::Attack.cache.respond_to?(:clear)
  end

  test "throttles comparison creation after 25 requests in 24 hours" do
    user = users(:jimmy)
    sign_in user

    # Make 25 successful requests (should succeed)
    25.times do
      post comparisons_path, params: { query: "test query" }
      assert_response :success
    end

    # 26th request should be throttled
    post comparisons_path, params: { query: "test query" }
    assert_response :too_many_requests
  end

  test "throttles comparison creation by IP after 5 requests" do
    # Simulate unauthenticated requests from same IP
    5.times do
      post comparisons_path, params: { query: "test query" }
    end

    # 6th request should be throttled
    post comparisons_path, params: { query: "test query" }
    assert_response :too_many_requests
  end

  test "admins bypass rate limiting" do
    admin = users(:admin)
    sign_in admin

    # Admins should be able to make unlimited requests
    30.times do
      post comparisons_path, params: { query: "test query" }
      assert_response :success
    end
  end
end
```

**Why Critical**: Rate limiting prevents cost explosion. Without this, a bad actor could create 1000s of comparisons and cost you $50-100 in minutes.

### 1.4: Admin Controller Authorization Tests (~30 min)

**File**: `test/controllers/admin/users_controller_test.rb`

**Test Admin-Only Access**:
```ruby
test "non-admin users cannot access whitelist management" do
  user = users(:jimmy) # Not an admin
  sign_in user

  get admin_users_path
  assert_redirected_to root_path
  assert_equal "You must be an admin to access this page.", flash[:alert]
end

test "unauthenticated users cannot access whitelist management" do
  get admin_users_path
  assert_redirected_to new_user_session_path
end

test "admins can access whitelist management" do
  admin = users(:admin)
  sign_in admin

  get admin_users_path
  assert_response :success
end
```

**Similar tests for `Admin::StatsController`**

**Why Critical**: Admin endpoints expose sensitive data (costs, all users) and powerful actions (whitelist management). Must be properly locked down.

---

## Phase 2: Cost Control & User Profile Backend (MEDIUM PRIORITY)

**Time**: 2-3 hours
**Why**: Foundation for `/api/v1/users/me` endpoints and cost tracking

### 2.1: User Profile Methods (~1.5 hours)

**File**: `app/models/user.rb`

**Add Methods**:
```ruby
class User < ApplicationRecord
  # ... existing code ...

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Returns comparisons created this month by this user
  def comparisons_count_this_month
    comparisons.where("created_at >= ?", Time.current.beginning_of_month).count
  end

  # Returns deep analyses created this month by this user
  def analyses_count_this_month
    analyses.where("created_at >= ?", Time.current.beginning_of_month).count
  end

  # Returns comparisons remaining today (25/day limit)
  def comparisons_remaining_today
    return Float::INFINITY if admin? # Unlimited for admins

    used_today = comparisons.where("created_at >= ?", Time.current.beginning_of_day).count
    [25 - used_today, 0].max
  end

  # Returns deep analyses remaining today (3/day limit)
  def analyses_remaining_today
    return Float::INFINITY if admin? # Unlimited for admins

    used_today = analyses.where("created_at >= ?", Time.current.beginning_of_day).count
    [3 - used_today, 0].max
  end

  # Returns total AI cost spent by this user (all time)
  def total_ai_cost_spent
    AiCost.where(user_id: id).sum(:cost_usd).to_f
  end

  # Returns AI cost spent this month by this user
  def ai_cost_spent_this_month
    AiCost.where(user_id: id)
          .where("date >= ?", Time.current.beginning_of_month.to_date)
          .sum(:cost_usd).to_f
  end

  # Soft delete user and anonymize data
  def soft_delete!
    transaction do
      update!(
        deleted_at: Time.current,
        email: "deleted_#{id}@example.com",
        github_username: "deleted_user_#{id}",
        github_avatar_url: nil
      )

      # Keep comparisons/analyses for data integrity, but anonymize
      comparisons.update_all(user_id: nil)
      analyses.update_all(user_id: nil)
    end
  end
end
```

**File**: `test/models/user_test.rb`

**Add Tests**:
```ruby
test "comparisons_count_this_month returns correct count" do
  user = users(:jimmy)

  # Create comparisons at different times
  Comparison.create!(user: user, user_query: "test1", created_at: 1.month.ago)
  Comparison.create!(user: user, user_query: "test2", created_at: Time.current)
  Comparison.create!(user: user, user_query: "test3", created_at: Time.current)

  assert_equal 2, user.comparisons_count_this_month
end

test "comparisons_remaining_today returns correct count" do
  user = users(:jimmy)

  # Create 23 comparisons today
  23.times do |i|
    Comparison.create!(user: user, user_query: "test#{i}", created_at: Time.current)
  end

  assert_equal 2, user.comparisons_remaining_today
end

test "comparisons_remaining_today returns 0 when limit exceeded" do
  user = users(:jimmy)

  # Create 25 comparisons today (at limit)
  25.times do |i|
    Comparison.create!(user: user, user_query: "test#{i}", created_at: Time.current)
  end

  assert_equal 0, user.comparisons_remaining_today
end

test "comparisons_remaining_today returns infinity for admins" do
  admin = users(:admin)

  # Create 30 comparisons (over normal limit)
  30.times do |i|
    Comparison.create!(user: admin, user_query: "test#{i}", created_at: Time.current)
  end

  assert_equal Float::INFINITY, admin.comparisons_remaining_today
end

test "total_ai_cost_spent returns sum of all user costs" do
  user = users(:jimmy)

  AiCost.create!(user: user, date: Date.today, cost_usd: 0.05, model: "gpt-5-mini")
  AiCost.create!(user: user, date: Date.yesterday, cost_usd: 0.10, model: "gpt-5")
  AiCost.create!(user: users(:other), date: Date.today, cost_usd: 0.20, model: "gpt-5")

  assert_in_delta 0.15, user.total_ai_cost_spent, 0.001
end

test "soft_delete! anonymizes user data" do
  user = users(:jimmy)
  original_email = user.email

  user.soft_delete!
  user.reload

  assert_not_nil user.deleted_at
  assert_not_equal original_email, user.email
  assert user.email.start_with?("deleted_")
end
```

### 2.2: Cost Tracking Verification (~30 min)

**File**: `test/services/open_ai_test.rb`

**Test Automatic Cost Tracking**:
```ruby
test "OpenAi.chat automatically creates AiCost record" do
  user = users(:jimmy)

  assert_difference "AiCost.count", 1 do
    OpenAi.new(user: user).chat(
      messages: [{ role: "user", content: "test" }],
      model: "gpt-5-mini",
      track_as: "test_operation"
    )
  end

  cost = AiCost.last
  assert_equal user.id, cost.user_id
  assert_equal Date.today, cost.date
  assert_equal "gpt-5-mini", cost.model
  assert cost.cost_usd > 0
end

test "OpenAi.chat creates anonymous cost record when no user provided" do
  assert_difference "AiCost.count", 1 do
    OpenAi.new.chat(
      messages: [{ role: "user", content: "test" }],
      model: "gpt-5-mini"
    )
  end

  cost = AiCost.last
  assert_nil cost.user_id # Anonymous
end
```

**Why Critical**: Every AI call MUST be tracked. If cost tracking fails silently, you won't know you're bleeding money.

---

## Phase 3: Controller Security & Business Logic (HIGH PRIORITY)

**Time**: 2-3 hours
**Why**: These controllers become your API endpoints - must be bulletproof

### 3.1: ComparisonsController Authorization Tests (~1 hour)

**File**: `test/controllers/comparisons_controller_test.rb`

**Test Authorization**:
```ruby
test "unauthenticated users cannot create comparisons" do
  post comparisons_path, params: { query: "test query" }
  assert_redirected_to new_user_session_path
end

test "authenticated users can create comparisons" do
  sign_in users(:jimmy)

  post comparisons_path, params: { query: "test query" }
  assert_response :success
end

test "users can only see their own comparisons in index" do
  user1 = users(:jimmy)
  user2 = users(:other)

  comp1 = Comparison.create!(user: user1, user_query: "user1 query")
  comp2 = Comparison.create!(user: user2, user_query: "user2 query")

  sign_in user1
  get comparisons_path

  assert_select "a", text: "user1 query"
  assert_select "a", text: "user2 query", count: 0 # Should not see other user's
end

test "admin can refresh comparisons" do
  admin = users(:admin)
  comparison = comparisons(:one)

  sign_in admin
  post comparisons_path(query: comparison.user_query, refresh: true)

  assert_response :success
end

test "non-admin cannot refresh comparisons" do
  user = users(:jimmy)
  comparison = comparisons(:one)

  sign_in user
  post comparisons_path(query: comparison.user_query, refresh: true)

  # Should create new comparison instead of refreshing
  assert_not_equal comparison.id, assigns(:comparison).id
end
```

### 3.2: RepositoriesController Authorization Tests (~30 min)

**File**: `test/controllers/repositories_controller_test.rb`

**Test Deep Analysis Authorization**:
```ruby
test "unauthenticated users cannot create deep analyses" do
  repo = repositories(:one)

  post create_analysis_repository_path(repo)
  assert_redirected_to new_user_session_path
end

test "authenticated users can create deep analyses within daily limit" do
  user = users(:jimmy)
  repo = repositories(:one)
  sign_in user

  # First analysis should succeed
  post create_analysis_repository_path(repo)
  assert_response :success
end

test "users cannot exceed daily deep analysis limit" do
  user = users(:jimmy)
  repo = repositories(:one)
  sign_in user

  # Create 3 analyses today (at limit)
  3.times do
    AnalysisDeep.create!(
      repository: repo,
      user: user,
      model_used: "gpt-5",
      created_at: Time.current
    )
  end

  # 4th analysis should fail
  post create_analysis_repository_path(repo)
  assert_response :unprocessable_entity
  assert_match /daily limit/, flash[:alert]
end
```

### 3.3: SearchComparisonsPresenter Tests (~1 hour)

**File**: `test/presenters/search_comparisons_presenter_test.rb` (create new)

**Test Search & Filter Logic**:
```ruby
require "test_helper"

class SearchComparisonPresenterTest < ActiveSupport::TestCase
  setup do
    @user = users(:jimmy)

    # Create test comparisons
    @comp1 = Comparison.create!(
      user: @user,
      user_query: "Rails authentication",
      technologies: "Rails, Ruby",
      created_at: 1.week.ago
    )

    @comp2 = Comparison.create!(
      user: @user,
      user_query: "Python web framework",
      technologies: "Python, Django",
      created_at: 1.month.ago
    )
  end

  test "returns all comparisons when no filters applied" do
    presenter = SearchComparisonsPresenter.new({})
    assert_equal 2, presenter.comparisons.count
  end

  test "filters by search term" do
    presenter = SearchComparisonsPresenter.new({ search: "Rails" })
    results = presenter.comparisons

    assert_equal 1, results.count
    assert_equal @comp1.id, results.first.id
  end

  test "filters by date range - week" do
    presenter = SearchComparisonsPresenter.new({ date: "week" })
    results = presenter.comparisons

    assert_equal 1, results.count
    assert_equal @comp1.id, results.first.id
  end

  test "filters by date range - month" do
    presenter = SearchComparisonsPresenter.new({ date: "month" })
    results = presenter.comparisons

    assert_equal 2, results.count # Both within month
  end

  test "has_filters? returns true when filters present" do
    presenter = SearchComparisonsPresenter.new({ search: "Rails" })
    assert presenter.has_filters?
  end

  test "has_filters? returns false when no filters" do
    presenter = SearchComparisonsPresenter.new({})
    refute presenter.has_filters?
  end

  test "sorts by newest when no search term" do
    presenter = SearchComparisonsPresenter.new({ sort: "newest" })
    results = presenter.comparisons

    assert_equal @comp1.id, results.first.id # Most recent first
  end

  test "preserves relevance order when searching" do
    # When searching, should not override with manual sort
    presenter = SearchComparisonsPresenter.new({ search: "Rails", sort: "newest" })
    # Should use search relevance, not "newest" sort
    # (test implementation depends on your search logic)
  end
end
```

---

## Phase 4: Admin Backend Verification (MEDIUM PRIORITY)

**Time**: 1 hour
**Why**: Verify what other Claude built, ensure it's API-ready

### 4.1: Review Admin Controllers (~30 min)

**Check**:
- [ ] `Admin::UsersController` exists and has proper authorization
- [ ] `Admin::StatsController` exists and has proper authorization
- [ ] Both use `before_action :require_admin!` or similar
- [ ] Error handling for unauthorized access
- [ ] Tests exist and pass

**Review Files**:
```bash
# Check if controllers exist
ls app/controllers/admin/

# Check authorization
grep -r "before_action" app/controllers/admin/
grep -r "require_admin" app/controllers/admin/

# Run existing tests
bin/rails test test/controllers/admin/
```

### 4.2: Document Admin Endpoints for API (~30 min)

**Create**: `docs/API_ADMIN_ENDPOINTS.md`

**Document**:
- `/admin/users` - List whitelisted users
- `/admin/users/:id` - Whitelist management (create, delete)
- `/admin/stats` - Cost dashboard
- Authentication requirements (must be admin)
- Rate limiting (if any)

---

## Security Checklist (Before API Launch)

Use this checklist before exposing any API endpoints:

### Authentication:
- [ ] OAuth flow tested and working
- [ ] Whitelist enforcement tested (User.from_omniauth)
- [ ] Non-whitelisted users blocked from accessing API
- [ ] JWT tokens or session cookies properly validated

### Authorization:
- [ ] User.admin? logic tested and working
- [ ] Admin endpoints reject non-admin users
- [ ] Users can only access their own data
- [ ] Admin actions properly logged

### Rate Limiting:
- [ ] Comparison creation limited to 25/day per user
- [ ] Deep analysis limited to 3/day per user
- [ ] IP-based rate limiting for unauthenticated requests
- [ ] Admins properly bypass rate limits
- [ ] Rate limit errors return proper HTTP status (429)

### Cost Control:
- [ ] Every AI call creates AiCost record
- [ ] AiCost records have user_id (for tracking)
- [ ] Daily rollup job working
- [ ] Budget alerts configured (optional)
- [ ] Cost per operation validated (comparisons ~$0.05-0.10, analysis ~$0.03-0.05)

### Data Protection:
- [ ] Users cannot access other users' comparisons
- [ ] Users cannot access other users' analyses
- [ ] Sensitive data (costs, emails) only exposed to owner/admin
- [ ] Account deletion properly anonymizes data

### Error Handling:
- [ ] Unauthorized access returns 401
- [ ] Forbidden access returns 403
- [ ] Rate limit exceeded returns 429
- [ ] Errors don't leak sensitive info (stack traces, DB details)

---

## Estimated Timeline

**Total Time**: 6-8 hours

- **Phase 1** (Auth/Authz): 2-3 hours ⚠️ CRITICAL
- **Phase 2** (User Profile): 2-3 hours 🔒 IMPORTANT
- **Phase 3** (Controllers): 2-3 hours ⚠️ CRITICAL
- **Phase 4** (Admin Verify): 1 hour 🔒 IMPORTANT

**Priority Order**:
1. Phase 1 (Auth/Authz) - Can't skip, must be bulletproof
2. Phase 3 (Controllers) - These become API endpoints
3. Phase 2 (User Profile) - Foundation for user endpoints
4. Phase 4 (Admin Verify) - Make sure admin stuff works

---

## After API Prep: Next Steps

Once all tests pass and security is verified:

1. **Design REST API** - Define endpoints, auth strategy, CORS
2. **Build API Controllers** - Namespace under `/api/v1/`
3. **Add API Authentication** - JWT tokens or session-based
4. **Test API Security** - Penetration testing, auth bypass attempts
5. **Deploy API** - Rails API-only mode on Render
6. **Build Next.js Frontend** - Beautiful UI consuming your secure API

**Rails will become**: Secure, well-tested API backend
**Next.js will become**: Beautiful frontend that can't be exploited
