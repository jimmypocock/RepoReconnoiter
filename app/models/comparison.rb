class Comparison < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  has_many :comparison_categories, dependent: :restrict_with_error
  has_many :categories, through: :comparison_categories
  has_many :comparison_repositories, dependent: :restrict_with_error
  has_many :repositories, through: :comparison_repositories

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :cost_usd, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :input_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :output_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :view_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :user_query, presence: true

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_save :calculate_cost, if: -> { model_used.present? && input_tokens.present? && output_tokens.present? }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(view_count: :desc) }
  scope :by_problem_domain, ->(domain) { where(problem_domain: domain) }
  scope :cached, -> { where("created_at > ?", 7.days.ago) }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def increment_view_count!
    increment!(:view_count)
  end

  def recommended_repository
    repositories.joins(:comparison_repositories)
      .where(comparison_repositories: { comparison_id: id })
      .order("comparison_repositories.rank ASC")
      .first
  end

  def total_tokens
    (input_tokens || 0) + (output_tokens || 0)
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def calculate_cost
    rates = case model_used
    when "gpt-4o-mini"
      { input: 0.150 / 1_000_000, output: 0.600 / 1_000_000 }
    when "gpt-4o"
      { input: 2.50 / 1_000_000, output: 10.00 / 1_000_000 }
    else
      return
    end

    self.cost_usd = (input_tokens * rates[:input]) + (output_tokens * rates[:output])
  end
end
