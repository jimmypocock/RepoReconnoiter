class QueuedAnalysisProcessor
  #--------------------------------------
  # CONSTANTS
  #--------------------------------------

  BATCH_COST_LIMIT = 0.10  # $0.10 per batch (~100 repos at $0.001 each)
  BATCH_SIZE = 20

  attr_reader :batch_cost, :failed_count, :processed_count

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def initialize
    @batch_cost = 0.0
    @processed_count = 0
    @failed_count = 0
  end

  def process_batch
    batch = QueuedAnalysis.ready_to_process.limit(BATCH_SIZE)

    return { processed: 0, failed: 0, cost: 0.0 } if batch.empty?

    batch.each do |queued|
      break if @batch_cost >= BATCH_COST_LIMIT

      process_one(queued)
    end

    { cost: @batch_cost, failed: @failed_count, processed: @processed_count }
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    delegate :process_batch, to: :new
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def assign_categories(repo, categories)
    category_matcher = CategoryMatcher.new

    categories.each do |cat|
      category = category_matcher.find_or_create(
        name: cat["name"],
        category_type: cat["category_type"]
      )

      repo.repository_categories.create!(
        category_id: category.id,
        confidence_score: cat["confidence"],
        assigned_by: "ai"
      )
    end
  end

  def assign_language_category(repo)
    return if repo.language.blank?

    category_matcher = CategoryMatcher.new
    category = category_matcher.find_or_create(
      name: repo.language,
      category_type: "technology"
    )

    unless repo.repository_categories.exists?(category_id: category.id)
      repo.repository_categories.create!(
        category_id: category.id,
        confidence_score: 1.0,
        assigned_by: "github_language"
      )
    end
  end

  def handle_failure(queued, error)
    queued.mark_failed!(error)

    # Retry if eligible
    queued.retry! if queued.can_retry?
  end

  def process_one(queued)
    queued.mark_processing!

    repo = queued.repository

    # Skip if already analyzed recently
    unless repo.needs_analysis?
      queued.mark_completed!
      @processed_count += 1
      return
    end

    # Run analysis
    analyzer = RepositoryAnalyzer.new
    result = analyzer.analyze(repo)

    # Create analysis record
    repo.analyses.create!(
      type: queued.analysis_type,
      model_used: "gpt-5-mini",
      summary: result[:summary],
      use_cases: result[:use_cases],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      is_current: true
    )

    # Create category associations
    assign_categories(repo, result[:categories])

    # Auto-assign technology category from GitHub language
    assign_language_category(repo)

    # Update timestamp and mark complete
    repo.update!(last_analyzed_at: Time.current)
    queued.mark_completed!

    # Track cost
    @batch_cost += repo.analyses.current.first&.cost_usd || 0
    @processed_count += 1
  rescue => e
    handle_failure(queued, e)
    @failed_count += 1
  end
end
