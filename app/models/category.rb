class Category < ApplicationRecord
  #--------------------------------------
  # CONSTANTS
  #--------------------------------------
  CATEGORY_TYPES = %w[problem_domain architecture_pattern maturity].freeze

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
  validates :category_type, presence: true, inclusion: {
    in: CATEGORY_TYPES,
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
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Find or create a category with fuzzy matching to avoid duplicates
    # First tries exact match, then fuzzy match, then creates new
    def find_or_create_by_fuzzy_match(name:, slug:, category_type:)
      # Normalize slug to ensure consistent matching
      normalized_slug = slug.to_s.parameterize

      # Try exact match first
      category = find_by(slug: normalized_slug, category_type: category_type)
      return category if category

      # Check for similar slugs to avoid duplicates
      similar = find_similar(normalized_slug, category_type)
      return similar if similar

      # Create new category
      create!(category_type:, name:, slug: normalized_slug)
    end

    private

    # Find a similar category based on word overlap in slug
    # Returns category if at least 70% of words match
    # Higher threshold (70% vs 50%) prevents false positives like:
    #   "react state management" matching "rails state management"
    def find_similar(slug, category_type)
      # Normalize the incoming slug to match database format
      normalized_slug = slug.to_s.parameterize
      slug_words = normalized_slug.split("-")
      return nil if slug_words.empty?

      where(category_type: category_type).find do |cat|
        cat_words = cat.slug.split("-")
        # Check if there's significant word overlap (at least 70% of words match)
        common_words = slug_words & cat_words
        overlap_ratio = common_words.size.to_f / [ slug_words.size, cat_words.size ].min
        overlap_ratio >= 0.7
      end
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def generate_slug
    self.slug = name.parameterize
  end
end
