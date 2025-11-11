class ComparisonCategory < ApplicationRecord
  #--------------------------------------
  # ENUMS
  #--------------------------------------

  enum :assigned_by, {
    ai: "ai",
    inherited: "inherited",
    inferred: "inferred"
  }, prefix: true

  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :category
  belongs_to :comparison

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :category_id, presence: true
  validates :comparison_id, presence: true, uniqueness: { scope: :category_id }
  validates :confidence_score, numericality: {
    greater_than_or_equal_to: 0.0,
    less_than_or_equal_to: 1.0,
    allow_nil: true
  }
end
