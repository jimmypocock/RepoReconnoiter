class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def failure
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def github
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication, remember_me: true
      set_flash_message(:notice, :success, kind: "GitHub") if is_navigational_format?
    else
      session["devise.github_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  rescue StandardError
    redirect_to root_path, alert: "Access denied. Email jimmycpocock+RepoReconnoiter@gmail.com to request access."
  end
end
