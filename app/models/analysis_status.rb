class AnalysisStatus < ApplicationRecord
  #--------------------------------------
  # ENUMS
  #--------------------------------------

  enum :status, {
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :processing

  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :repository, optional: true  # Nullable until completed (analysis is IN-PLACE on existing repo)
  belongs_to :user

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :session_id, presence: true, uniqueness: true
  validates :status, presence: true

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def complete!(repository)
    update!(
      repository: repository,
      status: :completed
    )
  end

  def fail!(error_message)
    update!(
      status: :failed,
      error_message: error_message
    )
  end
end
