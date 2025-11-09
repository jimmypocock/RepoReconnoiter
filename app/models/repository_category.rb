class RepositoryCategory < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :repository
  belongs_to :category, counter_cache: :repositories_count

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :repository_id, uniqueness: { scope: :category_id }
  validates :confidence_score, numericality: {
    greater_than_or_equal_to: 0.0,
    less_than_or_equal_to: 1.0,
    allow_nil: true
  }
  validates :assigned_by, inclusion: {
    in: %w[ai manual github_topics github_language],
    message: "%{value} is not a valid assignment method"
  }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :ai_assigned, -> { where(assigned_by: "ai") }
  scope :manually_assigned, -> { where(assigned_by: "manual") }
  scope :from_github, -> { where(assigned_by: [ "github_topics", "github_language" ]) }
  scope :high_confidence, -> { where("confidence_score >= ?", 0.7) }
  scope :low_confidence, -> { where("confidence_score < ?", 0.5) }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def confidence_percentage
    return nil if confidence_score.nil?

    (confidence_score * 100).round(1)
  end

  def ai_assigned?
    assigned_by == "ai"
  end

  def manually_assigned?
    assigned_by == "manual"
  end
end
