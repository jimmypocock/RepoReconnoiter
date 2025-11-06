class AnalysisCreator
  attr_reader :repository, :analysis_data, :analysis_id, :categories_linked, :categories_created, :cost_usd

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def initialize(repository:, analysis_data:)
    @repository = repository
    @analysis_data = analysis_data
  end

  # Creates the analysis record in the database
  # Creates analysis record, links categories, updates timestamp
  # Returns: self (with accessible attributes: analysis_id, categories_linked, categories_created, cost_usd)
  def call
    analysis = create_analysis_record
    stats = link_categories
    update_repository_timestamp

    @analysis_id = analysis.id
    @categories_linked = stats[:linked]
    @categories_created = stats[:created]
    @cost_usd = analysis.cost_usd

    self
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Convenience method for one-liner usage
    def call(repository:, analysis_data:)
      new(repository: repository, analysis_data: analysis_data).call
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def create_analysis_record
    repository.analyses.create!(
      analysis_type: "tier1_categorization",
      model_used: "gpt-4o-mini",
      summary: analysis_data[:summary],
      use_cases: analysis_data[:use_cases],
      input_tokens: analysis_data[:input_tokens],
      output_tokens: analysis_data[:output_tokens],
      is_current: true
    )
  end

  def link_categories
    categories_linked = 0
    categories_created = 0

    analysis_data[:categories].each do |cat_data|
      category = Category.find_or_create_by_fuzzy_match(
        name: cat_data["name"],
        slug: cat_data["slug"],
        category_type: cat_data["category_type"]
      )

      categories_created += 1 if category.previously_new_record?

      repository.repository_categories.find_or_create_by!(category: category) do |rc|
        rc.confidence_score = cat_data["confidence"]
        rc.assigned_by = "ai"
      end

      categories_linked += 1
    rescue => e
      Rails.logger.error "❌ Error linking category #{cat_data['slug']}: #{e.message}"
    end

    { linked: categories_linked, created: categories_created }
  end

  def update_repository_timestamp
    repository.update!(last_analyzed_at: Time.current)
  end
end
