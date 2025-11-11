class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def create
    @whitelisted_user = WhitelistedUser.new(whitelisted_user_params)

    if @whitelisted_user.save
      flash[:notice] = "User #{@whitelisted_user.github_username} has been whitelisted."
      redirect_to admin_users_path
    else
      flash[:alert] = "Error: #{@whitelisted_user.errors.full_messages.join(', ')}"
      redirect_to admin_users_path
    end
  end

  def destroy
    @whitelisted_user = WhitelistedUser.find(params[:id])
    username = @whitelisted_user.github_username

    if @whitelisted_user.destroy
      flash[:notice] = "User #{username} has been removed from whitelist."
    else
      flash[:alert] = "Error: #{@whitelisted_user.errors.full_messages.join(', ')}"
    end

    redirect_to admin_users_path
  end

  def index
    @whitelisted_users = WhitelistedUser.includes(:users).order(created_at: :desc)

    # Apply search filter if present
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @whitelisted_users = @whitelisted_users.where(
        "github_username ILIKE ? OR email ILIKE ?",
        search_term,
        search_term
      )
    end

    # Apply admin filter
    case params[:filter]
    when "admins"
      admin_ids = ENV.fetch("ALLOWED_ADMIN_GITHUB_IDS", "").split(",").map(&:strip).reject(&:empty?)
      @whitelisted_users = @whitelisted_users.where(github_id: admin_ids)
    when "non_admins"
      admin_ids = ENV.fetch("ALLOWED_ADMIN_GITHUB_IDS", "").split(",").map(&:strip).reject(&:empty?)
      @whitelisted_users = @whitelisted_users.where.not(github_id: admin_ids)
    end

    @pagy, @whitelisted_users = pagy(@whitelisted_users, items: 20)
    @whitelisted_user = WhitelistedUser.new
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def require_admin!
    redirect_to root_path, alert: "Access denied." unless current_user.admin?
  end

  def whitelisted_user_params
    params.require(:whitelisted_user).permit(:github_id, :github_username, :email, :notes)
  end
end
