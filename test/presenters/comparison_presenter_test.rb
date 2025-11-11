require "test_helper"

class ComparisonPresenterTest < ActiveSupport::TestCase
  #--------------------------------------
  # REFRESH AUTHORIZATION
  #--------------------------------------

  test "can_refresh? returns false for newly_created comparisons" do
    comparison = comparisons(:one)
    presenter = ComparisonPresenter.new(comparison, nil, newly_created: true)

    refute presenter.can_refresh?, "Should not allow refresh of newly created comparison"
  end

  test "can_refresh? returns true for admin users" do
    admin_user = users(:one)
    comparison = comparisons(:one)

    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: admin_user.github_id.to_s do
      presenter = ComparisonPresenter.new(comparison, admin_user, newly_created: false)
      assert presenter.can_refresh?, "Admin should be able to refresh comparison"
    end
  end

  test "can_refresh? returns false for non-admin users" do
    regular_user = users(:one)
    comparison = comparisons(:one)

    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: "99999" do
      presenter = ComparisonPresenter.new(comparison, regular_user, newly_created: false)
      refute presenter.can_refresh?, "Non-admin should not refresh"
    end
  end

  test "can_refresh? returns false when current_user is nil" do
    comparison = comparisons(:one)
    presenter = ComparisonPresenter.new(comparison, nil, newly_created: false)

    refute presenter.can_refresh?, "Should not allow refresh without user"
  end

  #--------------------------------------
  # SIMPLE DELEGATOR BEHAVIOR
  #--------------------------------------

  test "delegates comparison methods correctly" do
    comparison = comparisons(:one)
    presenter = ComparisonPresenter.new(comparison, nil)

    assert_equal comparison.user_query, presenter.user_query
    assert_equal comparison.id, presenter.id
    assert_equal comparison.repositories, presenter.repositories
  end
end
