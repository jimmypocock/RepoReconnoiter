class AiCost < ApplicationRecord
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
  # INSTANCE METHODS
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
    def budget_status(budget_per_month: 10.0)
      spent = total_cost_this_month
      percentage = (spent / budget_per_month * 100).round(1)

      status = case percentage
      when 0...50 then :healthy
      when 50...75 then :warning
      when 75...90 then :critical
      else :exceeded
      end

      {
        budget: budget_per_month,
        spent: spent,
        remaining: budget_per_month - spent,
        percentage: percentage,
        status: status
      }
    end

    def daily_average_this_month
      days = Time.current.day
      return 0 if days.zero?

      (total_cost_this_month / days).round(4)
    end

    def projected_monthly_cost
      daily_average = daily_average_this_month
      days_in_month = Time.current.end_of_month.day

      (daily_average * days_in_month).round(2)
    end

    def rollup_for_date(date, model)
      analyses = Analysis.where(model_used: model)
        .where("DATE(created_at) = ?", date)

      record = find_or_initialize_by(date: date, model_used: model)
      record.total_requests = analyses.count
      record.total_input_tokens = analyses.sum(:input_tokens) || 0
      record.total_output_tokens = analyses.sum(:output_tokens) || 0
      record.total_cost_usd = analyses.sum(:cost_usd) || 0
      record.save!

      record
    end

    def total_cost_by_model
      group(:model_used).sum(:total_cost_usd)
    end

    def total_cost_this_month
      this_month.sum(:total_cost_usd)
    end

    def total_cost_this_week
      this_week.sum(:total_cost_usd)
    end

    def total_cost_today
      for_date(Date.current).sum(:total_cost_usd)
    end
  end
end
