# ComparisonPresenter - Wraps Comparison model with presentation logic
#
# Provides view-related behavior and context that doesn't belong in the model.
# Uses SimpleDelegator to forward all Comparison methods automatically.
#
# Usage:
#   @comparison = ComparisonPresenter.new(comparison, current_user, newly_created: true)
#   @comparison.can_refresh?         # => false (brand new, don't show refresh)
#   @comparison.user_query           # => delegates to Comparison model
class ComparisonPresenter < SimpleDelegator
  attr_reader :current_user, :newly_created

  def initialize(comparison, current_user = nil, newly_created: nil)
    super(comparison)
    @current_user = current_user
    @newly_created = newly_created
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def can_refresh?
    current_user&.admin? && !newly_created
  end
end
