class ComparisonCategory < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :comparison
  belongs_to :category

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :assigned_by, inclusion: { in: %w[inferred ai] }
  validates :category_id, presence: true
  validates :comparison_id, presence: true, uniqueness: { scope: :category_id }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :ai_assigned, -> { where(assigned_by: "ai") }
  scope :inferred, -> { where(assigned_by: "inferred") }
end
