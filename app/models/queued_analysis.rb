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
    in: %w[tier1_categorization tier2_deep_dive],
    message: "%{value} is not a valid analysis type"
  }
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :retry_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  #--------------------------------------
  # SCOPES
  #--------------------------------------
  scope :ready_to_process, -> {
    where(status: "pending")
      .where("scheduled_for IS NULL OR scheduled_for <= ?", Time.current)
      .order(priority: :desc, created_at: :asc)
  }
  scope :tier1, -> { where(analysis_type: "tier1_categorization") }
  scope :tier2, -> { where(analysis_type: "tier2_deep_dive") }
  scope :stale, -> { where("created_at < ? AND status = ?", 7.days.ago, "pending") }
  scope :recent, -> { order(created_at: :desc) }

  #--------------------------------------
  # INSTANCE METHODS
  #--------------------------------------
  def tier1?
    analysis_type == "tier1_categorization"
  end

  def tier2?
    analysis_type == "tier2_deep_dive"
  end

  def mark_processing!
    update!(status: :processing, processed_at: Time.current)
  end

  def mark_completed!
    update!(status: :completed, processed_at: Time.current)
  end

  def mark_failed!(error)
    update!(
      status: :failed,
      error_message: error.to_s,
      processed_at: Time.current,
      retry_count: retry_count + 1
    )
  end

  def can_retry?
    status_failed? && retry_count < 3
  end

  def retry!
    return unless can_retry?

    update!(
      status: :pending,
      scheduled_for: calculate_retry_time,
      error_message: nil
    )
  end

  def scheduled?
    scheduled_for.present? && scheduled_for > Time.current
  end

  def overdue?
    scheduled_for.present? && scheduled_for < Time.current && status_pending?
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------
  class << self
    def enqueue_for_repository(repository, analysis_type:, priority: 0)
      create!(
        repository: repository,
        analysis_type: analysis_type,
        priority: priority,
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
