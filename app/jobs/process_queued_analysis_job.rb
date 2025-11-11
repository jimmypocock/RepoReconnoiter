class ProcessQueuedAnalysisJob < ApplicationJob
  queue_as :default

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def perform
    QueuedAnalysisProcessor.process_batch
  end
end
