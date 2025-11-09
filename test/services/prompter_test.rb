require "test_helper"

class PrompterTest < ActiveSupport::TestCase
  test "renders user_query_parser_system prompt successfully" do
    prompt = Prompter.render("user_query_parser_system")

    assert_not_nil prompt
    assert prompt.length > 100
  end

  test "user_query_parser_system prompt includes config-based star thresholds" do
    prompt = Prompter.render("user_query_parser_system")

    # Should contain the actual threshold values from config
    assert_includes prompt, "stars:>#{Rails.application.config.github_search[:min_stars]}"
    assert_includes prompt, "stars:>#{Rails.application.config.github_search[:popular_min_stars]}"
  end

  test "repository_comparer_system prompt renders successfully" do
    prompt = Prompter.render("repository_comparer_system")

    assert_not_nil prompt
    assert prompt.length > 100
  end

  test "repository_comparer_system prompt includes recency scoring" do
    prompt = Prompter.render("repository_comparer_system")

    assert_includes prompt, "Maintenance & Recency"
    assert_includes prompt, "AUTOMATIC PENALTIES"
    assert_includes prompt, "No updates in 2+ years"
  end
end
