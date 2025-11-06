class AiCost < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :user, optional: true

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :date, presence: true, uniqueness: { scope: :model_used }
  validates :model_used, presence: true
  validates :total_cost_usd, numericality: { greater_than_or_equal_to: 0 }
  validates :total_input_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_output_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_requests, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :for_date, ->(date) { where(date: date) }
  scope :for_model, ->(model) { where(model_used: model) }
  scope :recent, -> { order(date: :desc) }
  scope :this_month, -> { where("date >= ?", Time.current.beginning_of_month) }
  scope :this_week, -> { where("date >= ?", Time.current.beginning_of_week) }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def average_cost_per_request
    return 0 if total_requests.zero?

    (total_cost_usd / total_requests).round(6)
  end

  def average_tokens_per_request
    return 0 if total_requests.zero?

    (total_tokens / total_requests).round(0)
  end

  def total_tokens
    total_input_tokens + total_output_tokens
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------
  class << self
    def rollup_for_date(date, model)
      analyses = Analysis.by_model(model).created_on(date)

      record = find_or_initialize_by(date: date, model_used: model)
      record.total_requests = analyses.count
      record.total_input_tokens = analyses.sum(:input_tokens) || 0
      record.total_output_tokens = analyses.sum(:output_tokens) || 0
      record.total_cost_usd = analyses.sum(:cost_usd) || 0
      record.save!

      record
    end
  end
end
