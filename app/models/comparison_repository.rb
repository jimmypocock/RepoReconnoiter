class ComparisonRepository < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------
  belongs_to :comparison
  belongs_to :repository

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------
  validates :comparison_id, presence: true
  validates :rank, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :repository_id, presence: true
  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  #--------------------------------------
  # SCOPES
  #--------------------------------------
  scope :ranked, -> { order(rank: :asc) }
  scope :top_ranked, -> { where(rank: 1) }
end
