class QueuedAnalysis < ApplicationRecord
  #--------------------------------------
  # ENUMS
  #--------------------------------------

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :pending, prefix: true

  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :repository

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :analysis_type, presence: true, inclusion: {
    in: %w[Analysis AnalysisDeep],
    message: "%{value} is not a valid analysis type"
  }
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :retry_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :basic, -> { where(analysis_type: "Analysis") }
  scope :deep, -> { where(analysis_type: "AnalysisDeep") }
  scope :ready_to_process, -> {
    where(status: "pending")
      .where("scheduled_for IS NULL OR scheduled_for <= ?", Time.current)
      .order(priority: :desc, created_at: :asc)
  }
  scope :recent, -> { order(created_at: :desc) }
  scope :stale, -> { where("created_at < ? AND status = ?", 7.days.ago, "pending") }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def can_retry?
    status_failed? && retry_count < 3
  end

  def mark_failed!(error)
    raise "Can only fail processing items" unless status_processing?

    update!(
      status: :failed,
      error_message: error.to_s,
      processed_at: Time.current,
      retry_count: retry_count + 1
    )
  end

  def mark_processing!
    raise "Can only process pending items" unless status_pending?

    update!(status: :processing, processed_at: Time.current)
  end

  def mark_completed!
    raise "Can only complete processing items" unless status_processing?

    update!(status: :completed, processed_at: Time.current)
  end

  def overdue?
    scheduled_for.present? && scheduled_for < Time.current && status_pending?
  end

  def retry!
    return unless can_retry?

    update!(
      status: :pending,
      scheduled_for: calculate_retry_time,
      error_message: nil
    )
  end

  def basic?
    analysis_type == "Analysis"
  end

  def deep?
    analysis_type == "AnalysisDeep"
  end

  def scheduled?
    scheduled_for.present? && scheduled_for > Time.current
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------
  class << self
    def enqueue_for_repository(repository, analysis_type:, priority: 0)
      create!(
        analysis_type:,
        priority:,
        repository:,
        scheduled_for: Time.current
      )
    end

    def next_in_queue
      ready_to_process.first
    end

    def queue_size(type = nil)
      scope = status_pending
      scope = scope.where(analysis_type: type) if type
      scope.count
    end
  end

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  private

  def calculate_retry_time
    # Exponential backoff: 5min, 30min, 2hours
    delays = [ 5.minutes, 30.minutes, 2.hours ]
    Time.current + delays[retry_count] || 2.hours
  end
end
