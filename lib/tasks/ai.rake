namespace :ai do
  desc "Categorize a single repository by ID"
  task :categorize, [ :repo_id ] => :environment do |t, args|
    repo_id = args[:repo_id] || Repository.first&.id

    if repo_id.nil?
      puts "❌ No repositories found in database"
      exit 1
    end

    repo = Repository.find(repo_id)
    puts "\n🤖 Categorizing: #{repo.full_name}"
    puts "=" * 80

    result = AnalyzeRepositoryJob.perform_now(repo.id)

    puts "\n✅ Analysis Complete!"
    puts "   Analysis ID: #{result[:analysis_id]}"
    puts "   Categories Linked: #{result[:categories_linked]} (#{result[:categories_created]} new)"
    puts "   Cost: $#{result[:cost_usd].round(6)}"
    puts "\n📊 Analysis Details:"

    analysis = Analysis.find(result[:analysis_id])
    puts "   Summary: #{analysis.summary}"
    puts "\n   Use Cases:\n   #{analysis.use_cases}"
    puts "\n   Categories:"
    repo.reload.categories.each do |cat|
      rc = repo.repository_categories.find_by(category: cat)
      confidence = rc.confidence_score ? "(#{(rc.confidence_score * 100).round}%)" : ""
      puts "   - [#{cat.category_type}] #{cat.name} #{confidence}"
    end
  end

  desc "Categorize all uncategorized repositories (limit with LIMIT=N, default 10)"
  task categorize_all: :environment do
    limit = ENV["LIMIT"]&.to_i || 10
    repos = Repository.where(last_analyzed_at: nil).limit(limit)

    puts "\n🤖 Found #{repos.count} repositories to categorize (limit: #{limit})"
    puts "=" * 80

    total_cost = 0.0
    repos.each_with_index do |repo, index|
      puts "\n[#{index + 1}/#{repos.count}] #{repo.full_name}"
      result = AnalyzeRepositoryJob.perform_now(repo.id)
      total_cost += result[:cost_usd]
      puts "   Cost: $#{result[:cost_usd].round(6)} (Total: $#{total_cost.round(4)})"
    rescue => e
      puts "   ❌ Failed: #{e.message}"
    end

    uncategorized_remaining = Repository.where(last_analyzed_at: nil).count
    puts "\n✅ Batch complete! Total cost: $#{total_cost.round(4)}"
    puts "📊 #{uncategorized_remaining} uncategorized repositories remaining" if uncategorized_remaining > 0
  end

  desc "Show cost summary"
  task cost_summary: :environment do
    puts "\n💰 AI Cost Summary"
    puts "=" * 80

    # Calculate costs inline
    today = AiCost.for_date(Date.current).sum(:total_cost_usd)
    this_week = AiCost.this_week.sum(:total_cost_usd)
    this_month = AiCost.this_month.sum(:total_cost_usd)

    # Calculate projected cost
    days = Time.current.day
    daily_average = days.zero? ? 0 : (this_month / days).round(4)
    days_in_month = Time.current.end_of_month.day
    projected = (daily_average * days_in_month).round(2)

    # Calculate budget status
    budget_per_month = 10.0
    percentage = (this_month / budget_per_month * 100).round(1)
    status = case percentage
    when 0...50 then :healthy
    when 50...75 then :warning
    when 75...90 then :critical
    else :exceeded
    end

    puts "Today:       $#{today.round(4)}"
    puts "This Week:   $#{this_week.round(4)}"
    puts "This Month:  $#{this_month.round(4)}"
    puts "Projected:   $#{projected.round(2)}"
    puts "\nBudget Status: #{status.to_s.upcase}"
    puts "  Budget:     $#{budget_per_month}"
    puts "  Spent:      $#{this_month.round(4)}"
    puts "  Remaining:  $#{(budget_per_month - this_month).round(4)}"
    puts "  Used:       #{percentage}%"

    if status == :exceeded
      puts "\n⚠️  WARNING: Budget exceeded!"
    elsif status == :critical
      puts "\n⚠️  WARNING: Approaching budget limit!"
    end
  end
end
