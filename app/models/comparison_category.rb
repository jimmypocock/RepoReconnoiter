class ComparisonCategory < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------
  belongs_to :comparison
  belongs_to :category

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------
  validates :comparison_id, presence: true
  validates :category_id, presence: true
  validates :comparison_id, uniqueness: { scope: :category_id }
  validates :assigned_by, inclusion: { in: %w[inferred ai] }

  #--------------------------------------
  # SCOPES
  #--------------------------------------
  scope :inferred, -> { where(assigned_by: "inferred") }
  scope :ai_assigned, -> { where(assigned_by: "ai") }
end
