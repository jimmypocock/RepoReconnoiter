# Serializes Comparison objects to JSON for API responses
# Simple PORO approach - no gems required
#
# Usage:
#   ComparisonSerializer.new(comparison).as_json
#   ComparisonSerializer.collection(comparisons).as_json
#
class ComparisonSerializer
  attr_reader :comparison

  def initialize(comparison)
    @comparison = comparison
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def as_json
    {
      id: comparison.id,
      user_query: comparison.user_query,
      normalized_query: comparison.normalized_query,
      technologies: comparison.technologies,
      problem_domains: comparison.problem_domains,
      architecture_patterns: comparison.architecture_patterns,
      repos_compared_count: comparison.repos_compared_count,
      recommended_repo: comparison.recommended_repo_full_name,
      view_count: comparison.view_count,
      created_at: comparison.created_at.iso8601,
      updated_at: comparison.updated_at.iso8601,

      # Include related data if loaded (avoid N+1)
      categories: categories_json,
      repositories: repositories_json
    }
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Serialize a collection of comparisons
    # @param comparisons [ActiveRecord::Relation, Array<Comparison>]
    # @return [Array<Hash>]
    def collection(comparisons)
      comparisons.map { |comparison| new(comparison).as_json }
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def categories_json
    return [] unless comparison.association(:categories).loaded?

    comparison.categories.map do |category|
      {
        id: category.id,
        name: category.name,
        category_type: category.category_type
      }
    end
  end

  def repositories_json
    return [] unless comparison.association(:repositories).loaded?

    comparison.repositories.map do |repo|
      {
        id: repo.id,
        full_name: repo.full_name,
        description: repo.description,
        stargazers_count: repo.stargazers_count,
        language: repo.language,
        html_url: repo.html_url
      }
    end
  end
end
