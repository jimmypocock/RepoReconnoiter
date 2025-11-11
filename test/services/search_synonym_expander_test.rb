require "test_helper"

class SearchSynonymExpanderTest < ActiveSupport::TestCase
  #--------------------------------------
  # SYNONYM EXPANSION
  #--------------------------------------

  test "expand returns single term for unknown word" do
    result = SearchSynonymExpander.expand("unknown")
    assert_equal [ "unknown" ], result
  end

  test "expand returns synonyms for known term" do
    result = SearchSynonymExpander.expand("auth")
    assert_includes result, "auth"
    assert_includes result, "authentication"
    assert_includes result, "authorize"
    assert_includes result, "authorization"
  end

  test "expand handles case insensitivity" do
    result = SearchSynonymExpander.expand("AUTH")
    assert_includes result, "auth"
    assert_includes result, "authentication"
  end

  test "expand handles whitespace" do
    result = SearchSynonymExpander.expand("  job  ")
    assert_includes result, "job"
    assert_includes result, "jobs"
    assert_includes result, "queue"
  end

  test "expand returns unique terms" do
    result = SearchSynonymExpander.expand("job")
    assert_equal result, result.uniq
  end

  test "expand handles blank input" do
    assert_equal [ "" ], SearchSynonymExpander.expand("")
    assert_equal [ "" ], SearchSynonymExpander.expand(nil)
  end

  test "expand_all flattens multiple terms" do
    result = SearchSynonymExpander.expand_all([ "job", "auth" ])

    # Should include synonyms from both terms
    assert_includes result, "job"
    assert_includes result, "jobs"
    assert_includes result, "auth"
    assert_includes result, "authentication"
  end

  test "expand_all returns unique terms" do
    # "job" and "jobs" both expand to same set
    result = SearchSynonymExpander.expand_all([ "job", "jobs" ])
    assert_equal result, result.uniq
  end

  test "has_synonyms? returns true for known terms" do
    assert SearchSynonymExpander.has_synonyms?("auth")
    assert SearchSynonymExpander.has_synonyms?("job")
    assert SearchSynonymExpander.has_synonyms?("node")
  end

  test "has_synonyms? returns false for unknown terms" do
    refute SearchSynonymExpander.has_synonyms?("unknown")
    refute SearchSynonymExpander.has_synonyms?("random")
  end

  test "has_synonyms? is case insensitive" do
    assert SearchSynonymExpander.has_synonyms?("AUTH")
    assert SearchSynonymExpander.has_synonyms?("Job")
    assert SearchSynonymExpander.has_synonyms?("NODE")
  end

  #--------------------------------------
  # SYNONYM COVERAGE
  #--------------------------------------

  test "job synonyms include common variations" do
    result = SearchSynonymExpander.expand("job")
    assert_includes result, "job"
    assert_includes result, "jobs"
    assert_includes result, "queue"
    assert_includes result, "worker"
  end

  test "auth synonyms include common variations" do
    result = SearchSynonymExpander.expand("authentication")
    assert_includes result, "auth"
    assert_includes result, "authentication"
    assert_includes result, "authorize"
    assert_includes result, "authorization"
  end

  test "language synonyms include common aliases" do
    js_result = SearchSynonymExpander.expand("js")
    assert_includes js_result, "javascript"
    assert_includes js_result, "node"

    py_result = SearchSynonymExpander.expand("python")
    assert_includes py_result, "py"
  end
end
