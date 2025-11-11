require "test_helper"

class CategoryMatcherTest < ActiveSupport::TestCase
  setup do
    @matcher = CategoryMatcher.new

    # Stub embedding generation to avoid OpenAI API calls in tests
    def @matcher.generate_embedding(name)
      # Return a simple fixed-size embedding vector for testing
      [ 0.1, 0.2, 0.3 ]
    end
  end

  #--------------------------------------
  # FUZZY MATCHING TESTS
  #--------------------------------------

  test "finds similar existing category instead of creating duplicate" do
    # Count existing problem_domain categories before test
    initial_count = Category.where(category_type: "problem_domain").count

    # Create existing category
    existing = Category.create!(
      name: "Background Job Processing",
      category_type: "problem_domain",
      slug: "background-job-processing"
    )

    # Try to create similar category (minor spelling variation)
    result = @matcher.find_or_create(name: "Background job processing", category_type: "problem_domain")

    # Should return existing category (not create new one)
    assert_equal existing.id, result.id
    assert_equal "Background Job Processing", result.name
    # Should have only created 1 new category total
    assert_equal initial_count + 1, Category.where(category_type: "problem_domain").count
  end

  test "creates new category if no similar match found" do
    result = @matcher.find_or_create(name: "Email Processing", category_type: "problem_domain")

    assert result.persisted?
    assert_equal "Email Processing", result.name
    assert_equal "problem_domain", result.category_type
    assert_equal "email-processing", result.slug
  end

  test "only matches within same category type" do
    # Create technology category
    Category.create!(
      name: "Rails",
      category_type: "technology",
      slug: "rails"
    )

    # Try to create problem_domain category with similar name
    result = @matcher.find_or_create(name: "Rails", category_type: "problem_domain")

    # Should create new category (different type)
    assert_equal "problem_domain", result.category_type
    assert_equal 2, Category.where(name: "Rails").count
  end

  #--------------------------------------
  # INTEGRATION TESTS
  #--------------------------------------

  test "prevents duplicate technologies with fuzzy matching" do
    # Create Rails technology
    @matcher.find_or_create(name: "Rails", category_type: "technology")

    # Try variations
    rails1 = @matcher.find_or_create(name: "Ruby on Rails", category_type: "technology")
    rails2 = @matcher.find_or_create(name: "rails", category_type: "technology")

    # All should resolve to same category
    assert_equal rails1.id, rails2.id
    assert_equal 1, Category.where(category_type: "technology", name: "Rails").count
  end

  test "prevents duplicate problem domains with fuzzy matching" do
    # Create category
    @matcher.find_or_create(name: "Background Job Processing", category_type: "problem_domain")

    # Try similar variations (case differences, minor typos)
    cat1 = @matcher.find_or_create(name: "Background Job Processng", category_type: "problem_domain")  # Typo: missing 'i'
    cat2 = @matcher.find_or_create(name: "background job processing", category_type: "problem_domain")  # Case difference

    # Should all resolve to same category
    assert_equal cat1.id, cat2.id
  end

  test "generates appropriate default descriptions" do
    tech = @matcher.find_or_create(name: "Ruby", category_type: "technology")
    assert_match(/programming language/, tech.description)

    problem = @matcher.find_or_create(name: "Authentication", category_type: "problem_domain")
    assert_match(/authentication/, problem.description.downcase)
  end
end
