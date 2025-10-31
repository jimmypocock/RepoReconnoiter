class Analysis < ApplicationRecord
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
  validates :model_used, presence: true
  validates :cost_usd, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :input_tokens, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :output_tokens, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_save :calculate_cost, if: -> { input_tokens_changed? || output_tokens_changed? }
  after_create :rollup_daily_cost
  before_save :mark_previous_as_not_current, if: -> { is_current? && is_current_changed? }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :current, -> { where(is_current: true) }
  scope :tier1, -> { where(analysis_type: "tier1_categorization") }
  scope :tier2, -> { where(analysis_type: "tier2_deep_dive") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_model, ->(model) { where(model_used: model) }
  scope :expired, -> { where("expires_at < ?", Time.current) }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def cost_per_token
    return 0 if total_tokens.zero? || cost_usd.nil?
    (cost_usd / total_tokens).round(6)
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def tier1?
    analysis_type == "tier1_categorization"
  end

  def tier2?
    analysis_type == "tier2_deep_dive"
  end

  def total_tokens
    (input_tokens || 0) + (output_tokens || 0)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------
  class << self
    def average_cost_by_type
      group(:analysis_type).average(:cost_usd)
    end

    def total_cost(period = :all_time)
      case period
      when :today
        where("created_at >= ?", Time.current.beginning_of_day).sum(:cost_usd)
      when :this_week
        where("created_at >= ?", Time.current.beginning_of_week).sum(:cost_usd)
      when :this_month
        where("created_at >= ?", Time.current.beginning_of_month).sum(:cost_usd)
      else
        sum(:cost_usd)
      end
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def calculate_cost
    # OpenAI pricing as of 2025 (adjust as needed)
    # gpt-4o-mini: $0.150/1M input, $0.600/1M output
    # gpt-4o: $2.50/1M input, $10.00/1M output
    return unless input_tokens && output_tokens

    rates = case model_used
    when "gpt-4o-mini"
      { input: 0.150 / 1_000_000, output: 0.600 / 1_000_000 }
    when "gpt-4o"
      { input: 2.50 / 1_000_000, output: 10.00 / 1_000_000 }
    else
      { input: 0, output: 0 }
    end

    self.cost_usd = (input_tokens * rates[:input]) + (output_tokens * rates[:output])
  end

  def mark_previous_as_not_current
    repository.analyses
      .where(analysis_type: analysis_type, is_current: true)
      .where.not(id: id)
      .update_all(is_current: false)
  end

  def rollup_daily_cost
    AiCost.rollup_for_date(created_at.to_date, model_used)
  end
end
