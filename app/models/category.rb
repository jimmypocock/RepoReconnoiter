class Category < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------
  has_many :repository_categories, dependent: :destroy
  has_many :repositories, through: :repository_categories
  has_many :comparison_categories, dependent: :destroy
  has_many :comparisons, through: :comparison_categories

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :category_type, presence: true, inclusion: {
    in: %w[problem_domain architecture_pattern maturity],
    message: "%{value} is not a valid category type"
  }

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  #--------------------------------------
  # SCOPES
  #--------------------------------------
  scope :problem_domains, -> { where(category_type: "problem_domain") }
  scope :architecture_patterns, -> { where(category_type: "architecture_pattern") }
  scope :maturity_levels, -> { where(category_type: "maturity") }
  scope :popular, -> { order(repositories_count: :desc) }

  #--------------------------------------
  # INSTANCE METHODS
  #--------------------------------------
  def display_name
    name
  end

  def emoji
    case category_type
    when "problem_domain"
      "🎯"
    when "architecture_pattern"
      "🏗️"
    when "maturity"
      maturity_emoji
    else
      "📦"
    end
  end

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------
  private

  def generate_slug
    self.slug = name.parameterize
  end

  def maturity_emoji
    case slug
    when "experimental"
      "🔬"
    when "active-development"
      "🚧"
    when "production-ready"
      "✅"
    when "enterprise-grade"
      "🏢"
    when "abandoned"
      "💀"
    else
      "📊"
    end
  end
end
