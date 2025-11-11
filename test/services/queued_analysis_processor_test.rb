require "test_helper"

class QueuedAnalysisProcessorTest < ActiveSupport::TestCase
  setup do
    @repository = repositories(:no_analyses)

    # Stub OpenAI chat (RepositoryAnalyzer uses it internally)
    stub_openai_chat(response_content: '{
      "categories": [
        {"name": "Background Jobs", "category_type": "problem_domain", "confidence": 0.95}
      ],
      "summary": "Test summary",
      "use_cases": ["Email sending", "Report generation"]
    }')

    # Stub OpenAI embeddings (CategoryMatcher uses it internally)
    stub_openai_embeddings
  end

  #--------------------------------------
  # BATCH PROCESSING
  #--------------------------------------

  test "process_batch returns empty result when queue is empty" do
    QueuedAnalysis.delete_all

    result = QueuedAnalysisProcessor.process_batch

    assert_equal 0, result[:processed]
    assert_equal 0, result[:failed]
    assert_equal 0.0, result[:cost]
  end

  test "process_batch processes pending items and creates Analysis records" do
    QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    assert_difference "Analysis.count", 1 do
      result = QueuedAnalysisProcessor.process_batch

      assert_equal 1, result[:processed]
      assert_equal 0, result[:failed]
    end
  end

  test "process_batch marks queued items as completed" do
    queued = QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    QueuedAnalysisProcessor.process_batch

    assert queued.reload.status_completed?
  end

  test "process_batch assigns categories from AI response" do
    QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    assert_difference "@repository.repository_categories.count", 2 do # AI category + language category
      QueuedAnalysisProcessor.process_batch
    end
  end

  test "process_batch assigns language category from repository.language" do
    @repository.update!(language: "Ruby")
    QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    QueuedAnalysisProcessor.process_batch

    ruby_category = Category.find_by(name: "Ruby", category_type: "technology")
    assert_not_nil ruby_category
    assert @repository.repository_categories.exists?(category_id: ruby_category.id, assigned_by: "github_language")
  end

  test "process_batch updates repository last_analyzed_at" do
    QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    assert_nil @repository.last_analyzed_at

    QueuedAnalysisProcessor.process_batch

    assert_not_nil @repository.reload.last_analyzed_at
  end

  #--------------------------------------
  # LIMITS AND CONSTRAINTS
  #--------------------------------------

  test "process_batch respects BATCH_SIZE limit" do
    # Create 25 queued items (BATCH_SIZE is 20)
    25.times do |i|
      repo = Repository.create!(
        github_id: 999000 + i,
        node_id: "MDEwOlJlcG9zaXRvcnk5OTkwMDA=#{i}",
        name: "repo-#{i}",
        full_name: "test/repo-#{i}",
        html_url: "https://github.com/test/repo-#{i}",
        description: "Test repo #{i}",
        stargazers_count: 100,
        language: "Ruby",
        owner_login: "test"
      )
      QueuedAnalysis.create!(
        repository: repo,
        analysis_type: "Analysis",
        priority: 0
      )
    end

    result = QueuedAnalysisProcessor.process_batch

    # Should stop at BATCH_SIZE (20)
    assert_operator result[:processed], :<=, QueuedAnalysisProcessor::BATCH_SIZE
  end

  test "process_batch tracks cost in result" do
    QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    result = QueuedAnalysisProcessor.process_batch

    # Should track cost (will be very small with gpt-5-mini, returned as BigDecimal or Float)
    assert result[:cost].is_a?(Numeric)
    assert_operator result[:cost], :>, 0.0
  end

  #--------------------------------------
  # SKIP LOGIC
  #--------------------------------------

  test "process_batch skips repos that don't need_analysis?" do
    # Mark repository as recently analyzed
    @repository.update!(last_analyzed_at: 1.hour.ago)
    @repository.analyses.create!(
      type: "Analysis",
      model_used: "gpt-5-mini",
      summary: "Already analyzed",
      use_cases: [ "Test" ],
      input_tokens: 100,
      output_tokens: 50,
      is_current: true
    )

    queued = QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    # Should not create new analysis
    assert_no_difference "Analysis.count" do
      QueuedAnalysisProcessor.process_batch
    end

    # But should still mark as completed
    assert queued.reload.status_completed?
  end

  #--------------------------------------
  # ERROR HANDLING (via model tests - see queued_analysis_test.rb)
  #--------------------------------------
  # Note: Failure handling and retry logic are tested in the QueuedAnalysis model tests
  # Testing them here would require complex stubbing that persists across parallel tests

  #--------------------------------------
  # CLASS METHOD
  #--------------------------------------

  test "class method delegates to instance" do
    QueuedAnalysis.create!(
      repository: @repository,
      analysis_type: "Analysis",
      priority: 5
    )

    result = QueuedAnalysisProcessor.process_batch

    assert_equal 1, result[:processed]
  end
end
