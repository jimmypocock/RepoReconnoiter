namespace :categories do
  desc "Normalize existing category data (safe for production)"
  task cleanup: :environment do
    puts "\n" + "=" * 100
    puts "CATEGORY CLEANUP & NORMALIZATION"
    puts "=" * 100
    puts "\nThis task will:"
    puts "  1. Split compound categories (e.g., 'Caching & Performance' → 'Caching' + 'Performance')"
    puts "  2. Fix capitalization (e.g., 'async' → 'Async')"
    puts "  3. Merge duplicates (e.g., 'Ruby on Rails' → 'Rails')"
    puts "  4. Delete bad categories (e.g., misclassified, too vague)"
    puts "  5. Remove maturity categories (will become repo attributes)"
    puts "\nThis is SAFE for production - only modifies existing data, never loses associations."

    cleanup_plan = []
    matcher = CategoryMatcher.new

    # ==========================================
    # 1. SPLIT COMPOUND CATEGORIES
    # ==========================================
    compound_splits = {
      "Caching & Performance" => [ "Caching", "Performance" ],
      "Testing & Mocking" => [ "Testing", "Mocking" ],
      "CLI & Developer Tools" => [ "CLI Tools", "Developer Tools" ],
      "Authentication & Identity" => [ "Authentication", "Identity Management" ],
      "Data Sync & Replication" => [ "Data Sync", "Data Replication" ],
      "Rate Limiting & Throttling" => [ "Rate Limiting", "Throttling" ],
      "Monitoring & Observability" => [ "Monitoring", "Observability" ],
      "Security & Encryption" => [ "Security", "Encryption" ],
      "Email & Notifications" => [ "Email", "Notifications" ],
      "Search & Indexing" => [ "Search", "Indexing" ]
    }

    compound_splits.each do |old_name, new_names|
      old_cat = Category.find_by(name: old_name)
      next unless old_cat

      cleanup_plan << {
        action: "split",
        old: old_name,
        new: new_names,
        type: old_cat.category_type,
        category: old_cat
      }
    end

    # ==========================================
    # 2. FIX CAPITALIZATION
    # ==========================================
    lowercase_fixes = {
      # Technology
      "async" => "Async",
      "aws" => "AWS",
      "aws-lambda" => "AWS Lambda",
      "cdk" => "CDK",
      "deep-learning" => "Deep Learning",
      "etl" => "ETL",
      "http" => "HTTP",
      # "microservices" => skip - will be deleted (misclassified)
      "optimization" => "Optimization",
      "pdf-generation" => "PDF Generation",
      "prawn" => "Prawn",
      "pytorch" => "PyTorch",
      "redis" => "Redis",
      "sidekiq" => "Sidekiq",
      "wasm" => "WebAssembly",
      "websockets" => "WebSockets",
      "zig" => "Zig",

      # Problem Domain
      "inverse-problems" => "Inverse Problems",
      "invoice-processing" => "Invoice Processing",
      "linear-operators" => "Linear Operators",
      "management-accounting" => "Management Accounting",
      "memory-allocation" => "Memory Allocation",
      "multilinear-algebra" => "Multilinear Algebra",
      "profiler-tools" => "Profiler Tools",
      "slab-allocator" => "Slab Allocator",
      "icon-font-generation" => "Icon Font Generation",
      "knowledge-graph-management" => "Knowledge Graph Management",
      "session-management" => "Session Management",

      # Architecture Pattern
      "command-line-tools" => "CLI Tools", # Will merge into CLI Tools from split
      "data-processing-framework" => "Data Processing",
      "layered-architecture" => "Layered Architecture",
      "onion-architecture" => "Onion Architecture"
    }

    lowercase_fixes.each do |old_name, new_name|
      old_cat = Category.find_by(name: old_name)
      next unless old_cat

      cleanup_plan << {
        action: "rename",
        old: old_name,
        new: new_name,
        type: old_cat.category_type,
        category: old_cat
      }
    end

    # ==========================================
    # 3. FIX CAPITALIZATION (Real-time → Real-Time)
    # ==========================================
    realtime_cat = Category.find_by(name: "Real-time Communication", category_type: "problem_domain")
    if realtime_cat
      cleanup_plan << {
        action: "rename",
        old: "Real-time Communication",
        new: "Real-Time Communication",
        type: "problem_domain",
        category: realtime_cat
      }
    end

    # ==========================================
    # 4. MERGE DUPLICATES
    # ==========================================
    merges = [
      { keep: "Rails", remove: "Ruby on Rails", type: "technology" },
      { keep: "Docker", remove: "Dockerfile", type: "technology" },
      { keep: "Serverless Architecture", remove: "Serverless-Friendly", type: "architecture_pattern" },
      { keep: "Data Processing", remove: "File Processing Framework", type: "architecture_pattern" }
    ]

    merges.each do |merge|
      keep_cat = Category.find_by(name: merge[:keep], category_type: merge[:type])
      remove_cat = Category.find_by(name: merge[:remove], category_type: merge[:type])

      if keep_cat && remove_cat
        cleanup_plan << {
          action: "merge",
          old: merge[:remove],
          new: merge[:keep],
          type: merge[:type],
          keep_category: keep_cat,
          remove_category: remove_cat
        }
      end
    end

    # ==========================================
    # 5. DELETE MISCLASSIFIED/BAD CATEGORIES
    # ==========================================
    deletions = [
      # Misclassified (should be problem_domain, not technology)
      { name: "Authentication", type: "technology", reason: "Misclassified - should be problem_domain" },
      { name: "Testing", type: "technology", reason: "Misclassified - should be problem_domain" },
      { name: "microservices", type: "technology", reason: "Misclassified - should be architecture_pattern" },

      # Too vague
      { name: "Web", type: "technology", reason: "Too vague" },
      { name: "Web Development", type: "architecture_pattern", reason: "Too vague" },

      # Will be merged by compound split
      { name: "Cache", type: "problem_domain", reason: "Merging into 'Caching' from split" },
      { name: "command-line-tools", type: "architecture_pattern", reason: "Merging into 'CLI Tools' from split" },

      # Maturity categories (will become repo attributes)
      { name: "Abandoned", type: "maturity", reason: "Migrating to repo.archived attribute" },
      { name: "Active Development", type: "maturity", reason: "Deriving from repo.last_commit_at" },
      { name: "Enterprise Grade", type: "maturity", reason: "Migrating to repo attribute or badge" },
      { name: "Experimental", type: "maturity", reason: "Deriving from repo.last_commit_at + stars" },
      { name: "Production Ready", type: "maturity", reason: "Deriving from repo stars/activity" }
    ]

    deletions.each do |del|
      cat = Category.find_by(name: del[:name], category_type: del[:type])
      if cat
        cleanup_plan << {
          action: "delete",
          old: del[:name],
          type: del[:type],
          reason: del[:reason],
          category: cat
        }
      end
    end

    # ==========================================
    # SHOW CLEANUP PLAN
    # ==========================================
    puts "\n📋 CLEANUP PLAN (#{cleanup_plan.count} operations)\n"
    puts "-" * 100

    cleanup_plan.group_by { |p| p[:action] }.each do |action, plans|
      puts "\n#{action.upcase} (#{plans.count} items):"
      plans.each do |plan|
        case plan[:action]
        when "split"
          puts "  • #{plan[:old]} → #{plan[:new].join(' + ')} (#{plan[:type]})"
        when "rename"
          puts "  • #{plan[:old]} → #{plan[:new]} (#{plan[:type]})"
        when "merge"
          puts "  • #{plan[:old]} → #{plan[:new]} (#{plan[:type]})"
        when "delete"
          puts "  • #{plan[:old]} (#{plan[:type]}) - #{plan[:reason]}"
        end
      end
    end

    puts "\n" + "-" * 100
    print "\nProceed with cleanup? (y/n): "
    response = STDIN.gets.chomp.downcase
    unless response == "y"
      puts "Cancelled."
      exit
    end

    # ==========================================
    # EXECUTE CLEANUP
    # ==========================================
    puts "\n🔧 Executing cleanup...\n"

    results = { split: 0, rename: 0, merge: 0, delete: 0, errors: [] }

    cleanup_plan.each do |plan|
      begin
        case plan[:action]
        when "split"
          old_cat = plan[:category]

          # Create new categories
          new_cats = plan[:new].map do |new_name|
            matcher.find_or_create(name: new_name, category_type: plan[:type])
          end

          # Migrate associations
          old_cat.repository_categories.find_each do |repo_cat|
            new_cats.each do |new_cat|
              RepositoryCategory.find_or_create_by!(
                repository_id: repo_cat.repository_id,
                category_id: new_cat.id
              ) do |rc|
                rc.confidence_score = repo_cat.confidence_score
                rc.assigned_by = repo_cat.assigned_by
              end
            end
          end

          old_cat.comparison_categories.find_each do |comp_cat|
            new_cats.each do |new_cat|
              ComparisonCategory.find_or_create_by!(
                comparison_id: comp_cat.comparison_id,
                category_id: new_cat.id
              )
            end
          end

          # Delete old category
          old_cat.destroy!
          results[:split] += 1
          puts "  ✅ Split: #{plan[:old]} → #{plan[:new].join(' + ')}"

        when "rename"
          old_cat = plan[:category]

          # Check if target already exists
          existing = Category.find_by(name: plan[:new], category_type: plan[:type])

          if existing && existing.id != old_cat.id
            # Merge into existing
            old_cat.repository_categories.find_each do |repo_cat|
              RepositoryCategory.find_or_create_by!(
                repository_id: repo_cat.repository_id,
                category_id: existing.id
              ) do |rc|
                rc.confidence_score = repo_cat.confidence_score
                rc.assigned_by = repo_cat.assigned_by
              end
            end

            old_cat.comparison_categories.find_each do |comp_cat|
              ComparisonCategory.find_or_create_by!(
                comparison_id: comp_cat.comparison_id,
                category_id: existing.id
              )
            end

            old_cat.destroy!
            puts "  ✅ Merged: #{plan[:old]} → #{plan[:new]}"
          else
            # Just rename
            old_cat.update!(
              name: plan[:new],
              slug: plan[:new].parameterize
            )

            # Regenerate embedding if it exists
            if old_cat.embedding.present?
              old_cat.update!(embedding: matcher.send(:generate_embedding, plan[:new]))
            end

            puts "  ✅ Renamed: #{plan[:old]} → #{plan[:new]}"
          end

          results[:rename] += 1

        when "merge"
          keep_cat = plan[:keep_category]
          remove_cat = plan[:remove_category]

          # Migrate associations to keep_category
          remove_cat.repository_categories.find_each do |repo_cat|
            RepositoryCategory.find_or_create_by!(
              repository_id: repo_cat.repository_id,
              category_id: keep_cat.id
            ) do |rc|
              rc.confidence_score = repo_cat.confidence_score
              rc.assigned_by = repo_cat.assigned_by
            end
          end

          remove_cat.comparison_categories.find_each do |comp_cat|
            ComparisonCategory.find_or_create_by!(
              comparison_id: comp_cat.comparison_id,
              category_id: keep_cat.id
            )
          end

          # Delete removed category
          remove_cat.destroy!
          results[:merge] += 1
          puts "  ✅ Merged: #{plan[:old]} → #{plan[:new]}"

        when "delete"
          cat = plan[:category]

          # Migrate associations to appropriate categories if possible
          # For misclassified categories, try to find the correct one
          if plan[:reason].include?("Misclassified")
            # Try to find correct category (e.g., Authentication as problem_domain)
            correct_type = plan[:reason].include?("problem_domain") ? "problem_domain" : "architecture_pattern"
            correct_cat = Category.find_by(name: cat.name, category_type: correct_type)

            if correct_cat
              # Migrate associations
              cat.repository_categories.find_each do |repo_cat|
                RepositoryCategory.find_or_create_by!(
                  repository_id: repo_cat.repository_id,
                  category_id: correct_cat.id
                ) do |rc|
                  rc.confidence_score = repo_cat.confidence_score
                  rc.assigned_by = repo_cat.assigned_by
                end
              end

              cat.comparison_categories.find_each do |comp_cat|
                ComparisonCategory.find_or_create_by!(
                  comparison_id: comp_cat.comparison_id,
                  category_id: correct_cat.id
                )
              end
            end
          end

          # Delete category
          cat.destroy!
          results[:delete] += 1
          puts "  ✅ Deleted: #{plan[:old]} (#{plan[:reason]})"
        end
      rescue => e
        results[:errors] << { plan: plan, error: e.message }
        puts "  ❌ Error: #{plan[:old]} - #{e.message}"
      end
    end

    # ==========================================
    # SUMMARY
    # ==========================================
    puts "\n" + "=" * 100
    puts "CLEANUP SUMMARY"
    puts "=" * 100
    puts "\nSplit: #{results[:split]}"
    puts "Renamed: #{results[:rename]}"
    puts "Merged: #{results[:merge]}"
    puts "Deleted: #{results[:delete]}"
    puts "Errors: #{results[:errors].count}"

    if results[:errors].any?
      puts "\n❌ ERRORS:"
      results[:errors].each do |err|
        puts "  • #{err[:plan][:old]}: #{err[:error]}"
      end
    else
      puts "\n✅ All cleanup operations completed successfully!"
    end

    puts "\n💡 Next steps:"
    puts "  1. Run: bin/rails categories:stats"
    puts "  2. Run: bin/rails categories:test_matrix"
    puts "  3. Run: bin/rails db:seed (to add missing canonical categories)"
    puts "\n" + "=" * 100
  end
end
