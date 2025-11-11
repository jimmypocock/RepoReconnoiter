class Analysis < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :repository

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :cost_usd, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :input_tokens, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :model_used, presence: true
  validates :output_tokens, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_save :calculate_cost, if: -> { input_tokens_changed? || output_tokens_changed? }
  before_save :mark_previous_as_not_current, if: -> { is_current? && is_current_changed? }
  after_create :rollup_daily_cost

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :basic, -> { where(type: "Analysis") }
  scope :by_model, ->(model) { where(model_used: model) }
  scope :created_on, ->(date) { where("DATE(created_at) = ?", date) }
  scope :current, -> { where(is_current: true) }
  scope :deep, -> { where(type: "AnalysisDeep") }
  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def cost_per_token
    return 0 if total_tokens.zero? || cost_usd.nil?

    (cost_usd / total_tokens).round(6)
  end

  def deep?
    is_a?(AnalysisDeep)
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def total_tokens
    (input_tokens || 0) + (output_tokens || 0)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------
  class << self
    def average_cost_by_type
      group(:type).average(:cost_usd)
    end

    def total_cost(period = :all_time)
      case period
      when :today
        today.sum(:cost_usd)
      when :this_week
        this_week.sum(:cost_usd)
      when :this_month
        this_month.sum(:cost_usd)
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
    return unless input_tokens && output_tokens

    self.cost_usd = OpenAi.calculate_cost(
      model: model_used,
      input_tokens: input_tokens,
      output_tokens: output_tokens
    )
  end

  def mark_previous_as_not_current
    repository.analyses
      .where(type: type, is_current: true)
      .where.not(id: id)
      .update_all(is_current: false)
  end

  def rollup_daily_cost
    AiCost.rollup_for_date(created_at.to_date, model_used)
  end
end
