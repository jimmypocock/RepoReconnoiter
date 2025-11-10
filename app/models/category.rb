class Category < ApplicationRecord
  #--------------------------------------
  # ENUMS
  #--------------------------------------

  enum :category_type, {
    architecture_pattern: "architecture_pattern",
    problem_domain: "problem_domain",
    technology: "technology"
  }

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
  validates :slug, presence: true, uniqueness: { scope: :category_type }

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :popular, -> { order(repositories_count: :desc) }

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def generate_slug
    self.slug = name.parameterize
  end
end
