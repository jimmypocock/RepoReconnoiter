class CategorizeRepositoryJob < ApplicationJob
  queue_as :default

  def perform(repository_id)
    repository = Repository.find(repository_id)
    openai = OpenaiService.new

    Rails.logger.info "🤖 Starting Tier 1 analysis for #{repository.full_name}..."

    # Call OpenAI to categorize the repository
    result = openai.categorize_repository(repository)

    # Create the analysis record
    analysis = repository.analyses.create!(
      analysis_type: "tier1_categorization",
      model_used: "gpt-4o-mini",
      summary: result[:summary],
      use_cases: result[:use_cases],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      is_current: true
    )

    # Link categories to the repository
    categories_linked = 0
    categories_created = 0

    result[:categories].each do |cat_data|
      category = find_or_create_category(
        name: cat_data["name"],
        slug: cat_data["slug"],
        category_type: cat_data["category_type"]
      )

      if category.previously_new_record?
        categories_created += 1
        Rails.logger.info "   ✨ Created new category: #{category.name} (#{category.category_type})"
      end

      repository.repository_categories.find_or_create_by!(category: category) do |rc|
        rc.confidence_score = cat_data["confidence"]
        rc.assigned_by = "ai"
      end

      categories_linked += 1
    rescue => e
      Rails.logger.error "❌ Error linking category #{cat_data['slug']}: #{e.message}"
    end

    # Update the repository's analysis timestamp
    repository.update!(last_analyzed_at: Time.current)

    Rails.logger.info "✅ Analysis complete for #{repository.full_name}"
    Rails.logger.info "   Categories: #{categories_linked} (#{categories_created} new)"
    Rails.logger.info "   Tokens: #{result[:input_tokens]} in / #{result[:output_tokens]} out"
    Rails.logger.info "   Cost: $#{analysis.cost_usd.round(6)}"

    {
      analysis_id: analysis.id,
      categories_linked: categories_linked,
      categories_created: categories_created,
      cost_usd: analysis.cost_usd
    }
  rescue => e
    Rails.logger.error "❌ Failed to analyze #{repository.full_name}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end

  private

  def find_or_create_category(name:, slug:, category_type:)
    # Try exact match first
    category = Category.find_by(slug: slug, category_type: category_type)
    return category if category

    # Check for similar slugs to avoid duplicates
    similar = find_similar_category(slug, category_type)
    if similar
      Rails.logger.info "   🔗 Using existing similar category: '#{similar.slug}' for '#{slug}'"
      return similar
    end

    # Create new category
    Category.create!(
      name: name,
      slug: slug,
      category_type: category_type
    )
  end

  def find_similar_category(slug, category_type)
    slug_words = slug.split("-")
    return nil if slug_words.empty?

    Category.where(category_type: category_type).find do |cat|
      cat_words = cat.slug.split("-")
      # Check if there's significant word overlap (at least 50% of words match)
      common_words = slug_words & cat_words
      overlap_ratio = common_words.size.to_f / [slug_words.size, cat_words.size].min
      overlap_ratio >= 0.5
    end
  end
end
