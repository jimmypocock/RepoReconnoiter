class AnalyzeRepositoryJob < ApplicationJob
  queue_as :default

  def perform(repository_id)
    repository = Repository.find(repository_id)

    # Analyze repository then create the Analysis record
    analysis_data = RepositoryAnalyzer.analyze(repository)
    AnalysisCreator.call(repository:, analysis_data:)
  end
end
