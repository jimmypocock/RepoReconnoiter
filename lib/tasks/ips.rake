# IP Blocklist Management Tasks
#
# Manage blocked IP addresses for Rack::Attack security.
# IPs are blocked via ENV["BLOCKED_IPS"] environment variable.
# Requires redeploy to take effect (~2-3 minutes on Render).
#
# Examples:
#   bin/rails ips:list            # List all currently blocked IPs
#   bin/rails ips:test[1.2.3.4]   # Test if specific IP is blocked
#   bin/rails ips:docs            # Show full documentation

namespace :ips do
  desc "List all currently blocked IP addresses"
  task list: :environment do
    blocked_ips = ENV.fetch("BLOCKED_IPS", "").split(",").map(&:strip).reject(&:empty?)

    if blocked_ips.empty?
      puts "No IPs are currently blocked."
      puts ""
      puts "To block an IP:"
      puts "  1. Set BLOCKED_IPS environment variable in Render dashboard"
      puts "  2. Format: BLOCKED_IPS=\"1.2.3.4,5.6.7.8\""
      puts "  3. Redeploy (automatic on git push)"
    else
      puts "Blocked IP Addresses:"
      puts "=" * 50
      blocked_ips.each_with_index do |ip, index|
        puts "#{index + 1}. #{ip}"
      end
      puts "=" * 50
      puts "Total: #{blocked_ips.count} IP(s) blocked"
      puts ""
      puts "To unblock:"
      puts "  1. Update BLOCKED_IPS in Render dashboard"
      puts "  2. Redeploy"
    end
  end

  desc "Test if a specific IP is blocked"
  task :test, [ :ip ] => :environment do |t, args|
    ip = args[:ip]

    if ip.blank?
      puts "Error: IP address required"
      puts "Usage: bin/rails ips:test[1.2.3.4]"
      exit 1
    end

    blocked_ips = ENV.fetch("BLOCKED_IPS", "").split(",").map(&:strip)

    if blocked_ips.include?(ip)
      puts "✅ IP #{ip} IS blocked"
      puts ""
      puts "This IP will receive 403 Forbidden for all requests."
    else
      puts "❌ IP #{ip} is NOT blocked"
      puts ""
      puts "This IP can access the application (subject to rate limits)."
    end
  end

  desc "Generate documentation for blocking IPs"
  task docs: :environment do
    puts <<~DOCS
      IP Blocking Documentation
      ==========================================

      ## Current Setup

      RepoReconnoiter uses ENV-based IP blocking via Rack::Attack.

      **Format:**
        BLOCKED_IPS="1.2.3.4,5.6.7.8,9.10.11.12"

      **Pros:**
        ✅ Simple to implement
        ✅ No database overhead
        ✅ Works well at current scale (0-2 blocks per year expected)

      **Cons:**
        ⚠️  Requires redeploy (~2-3 minutes on Render)
        ⚠️  Not instant like database blocking

      ==========================================
      ## How to Block an IP
      ==========================================

      ### Option 1: Render Dashboard (Production)

      1. Go to Render Dashboard → RepoReconnoiter → Environment
      2. Add or update: BLOCKED_IPS="1.2.3.4"
      3. Click "Save" (triggers automatic redeploy)
      4. Wait 2-3 minutes for deploy
      5. Verify: bin/rails ips:list (on Render shell)

      ### Option 2: Git Commit (Development)

      1. Update .env file: BLOCKED_IPS="127.0.0.1"
      2. Restart server: bin/dev
      3. Test: curl http://localhost:3000

      ==========================================
      ## Commands
      ==========================================

      # List all blocked IPs
      bin/rails ips:list

      # Test if specific IP is blocked
      bin/rails ips:test[1.2.3.4]

      # Show this help
      bin/rails ips:docs

      ==========================================
      ## When to Block an IP
      ==========================================

      ✅ Good reasons:
        - Persistent attacks bypassing rate limits
        - Active exploitation of vulnerability
        - Coordinated abuse from single IP

      ❌ Bad reasons:
        - Single failed request (probably legitimate error)
        - Abusive API key holder (revoke key instead)
        - Scraping attempt (authentication prevents this)

      ==========================================
      ## Alternatives to IP Blocking
      ==========================================

      1. **Revoke API keys** (instant, no redeploy)
         - bin/rails api_keys:revoke ID=123
         - Preferred for abusive API key holders

      2. **Cloudflare blocking** (instant, no redeploy)
         - Cloudflare dashboard → Security → IP Access Rules
         - Blocks at edge before hitting your server

      3. **Rate limit adjustment** (requires redeploy)
         - Edit config/initializers/rack_attack.rb
         - Lower limits for specific endpoints

      ==========================================
      ## Upgrading to Database Blocking
      ==========================================

      If you block >5 IPs in 3 months, consider database blocking:

      1. Create blocked_ips table (migration)
      2. Update rack_attack.rb to query database
      3. Create admin UI or rake task for management
      4. Gain instant blocking without redeploys

      Estimated implementation: 30-60 minutes

      Not needed yet - ENV blocking is sufficient at current scale.

      ==========================================
    DOCS
  end
end
