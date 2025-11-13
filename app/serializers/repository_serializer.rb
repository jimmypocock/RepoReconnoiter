# Serializes Repository objects to JSON for API responses
# Simple PORO approach - no gems required
#
# Usage:
#   RepositorySerializer.new(repository).as_json
#   RepositorySerializer.collection(repositories).as_json
#
class RepositorySerializer
  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def as_json
    {
      id: repository.id,
      github_id: repository.github_id,
      full_name: repository.full_name,
      name: repository.name,
      description: repository.description,
      html_url: repository.html_url,
      homepage_url: repository.homepage_url,
      language: repository.language,
      stargazers_count: repository.stargazers_count,
      forks_count: repository.forks_count,
      open_issues_count: repository.open_issues_count,
      watchers_count: repository.watchers_count,
      topics: repository.topics || [],
      license: repository.license,
      is_fork: repository.is_fork,
      archived: repository.archived,
      github_created_at: repository.github_created_at&.iso8601,
      github_updated_at: repository.github_updated_at&.iso8601,
      github_pushed_at: repository.github_pushed_at&.iso8601,

      # Owner info
      owner_login: repository.owner_login,
      owner_avatar_url: repository.owner_avatar_url,
      owner_type: repository.owner_type,

      # Include related data if loaded (avoid N+1)
      categories: categories_json,
      analyses: analyses_json
    }
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Serialize a collection of repositories
    # @param repositories [ActiveRecord::Relation, Array<Repository>]
    # @return [Array<Hash>]
    def collection(repositories)
      repositories.map { |repository| new(repository).as_json }
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def analyses_json
    return [] unless repository.association(:analyses).loaded?

    repository.analyses.map do |analysis|
      {
        id: analysis.id,
        type: analysis.type,
        model_used: analysis.model_used,
        is_current: analysis.is_current,
        created_at: analysis.created_at.iso8601,

        # Basic analysis fields (always present)
        summary: analysis.summary,
        use_cases: analysis.use_cases,

        # Deep analysis fields (only for AnalysisDeep)
        readme_analysis: analysis.try(:readme_analysis),
        issues_analysis: analysis.try(:issues_analysis),
        maintenance_analysis: analysis.try(:maintenance_analysis),
        adoption_analysis: analysis.try(:adoption_analysis),
        security_analysis: analysis.try(:security_analysis)
      }.compact # Remove nil values
    end
  end

  def categories_json
    return [] unless repository.association(:categories).loaded?

    repository.categories.map do |category|
      {
        id: category.id,
        name: category.name,
        category_type: category.category_type
      }
    end
  end
end
