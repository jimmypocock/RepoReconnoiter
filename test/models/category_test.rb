require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "should require name" do
    category = Category.new(category_type: "technology", slug: "test")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "should require slug" do
    category = Category.new(name: "Test", category_type: "technology")
    assert category.valid?, "Category should auto-generate slug from name"
    assert_equal "test", category.slug
  end

  test "should auto-generate slug from name" do
    category = Category.new(name: "Ruby on Rails", category_type: "technology")
    assert category.valid?
    assert_equal "ruby-on-rails", category.slug
  end

  test "should require unique slug within category_type" do
    existing = categories(:ruby)
    duplicate = Category.new(
      name: "Ruby Duplicate",
      slug: existing.slug,
      category_type: existing.category_type
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should allow same slug across different category_types" do
    # Create "Authentication" as technology
    tech_auth = Category.create!(
      name: "Authentication",
      slug: "authentication",
      category_type: "technology"
    )

    # Create "Authentication" as problem_domain
    problem_auth = Category.create!(
      name: "Authentication",
      slug: "authentication",
      category_type: "problem_domain"
    )

    assert tech_auth.persisted?
    assert problem_auth.persisted?
    assert_equal tech_auth.slug, problem_auth.slug
    assert_not_equal tech_auth.category_type, problem_auth.category_type
  end

  test "should have associations" do
    category = categories(:ruby)
    assert_respond_to category, :repositories
    assert_respond_to category, :repository_categories
    assert_respond_to category, :comparisons
    assert_respond_to category, :comparison_categories
  end
end
