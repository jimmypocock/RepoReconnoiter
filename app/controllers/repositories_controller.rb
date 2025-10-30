class RepositoriesController < ApplicationController
  def index
    scope = Repository.includes(:categories, :analyses)
      .order(stargazers_count: :desc)

    # Filter by category if provided
    if params[:category_id].present?
      scope = scope.joins(:categories).where(categories: { id: params[:category_id] })
    end

    # Filter by category type if provided
    if params[:category_type].present?
      scope = scope.joins(:categories).where(categories: { category_type: params[:category_type] })
    end

    @pagy, @repositories = pagy(scope, limit: 20)
    @categories = Category.order(:category_type, :name)
  end
end
