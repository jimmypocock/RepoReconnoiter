class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Ordering scopes
  scope :recent, -> { order(created_at: :desc) }

  # Calendar-based time scopes (beginning of period to now)
  scope :this_month, -> { where("created_at >= ?", Time.current.beginning_of_month) }
  scope :this_week, -> { where("created_at >= ?", Time.current.beginning_of_week) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }

  # Rolling time period scopes (last N days)
  scope :past_30_days, -> { where("created_at >= ?", 30.days.ago) }
  scope :past_7_days, -> { where("created_at >= ?", 7.days.ago) }
end
