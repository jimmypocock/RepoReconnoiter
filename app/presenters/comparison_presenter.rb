# ComparisonPresenter - Wraps Comparison model with presentation logic
#
# Provides view-related behavior and context that doesn't belong in the model.
# Uses SimpleDelegator to forward all Comparison methods automatically.
#
# Usage:
#   @comparison = ComparisonPresenter.new(comparison, newly_created: true)
#   @comparison.can_refresh?         # => false (brand new, don't show refresh)
#   @comparison.user_query           # => delegates to Comparison model
class ComparisonPresenter < SimpleDelegator
  attr_reader :newly_created

  def initialize(comparison, newly_created: nil)
    super(comparison)
    @newly_created = newly_created
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # TODO: Move to ComparisonPolicy when Phase 3.7 (user auth) is implemented
  # This is authorization logic, not business logic
  def can_refresh?(user = nil)
    Rails.env.development? && !newly_created
    # Future: user&.admin?
  end
end
