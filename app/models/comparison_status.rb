class ComparisonStatus < ApplicationRecord
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

  belongs_to :comparison, optional: true  # Nullable until completed
  belongs_to :user

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :session_id, presence: true, uniqueness: true
  validates :status, presence: true

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def complete!(comparison)
    update!(
      comparison: comparison,
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
