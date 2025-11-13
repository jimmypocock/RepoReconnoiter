require "test_helper"

class SessionExchangeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:one)
    @admin.update!(github_id: ENV.fetch("ALLOWED_ADMIN_GITHUB_IDS", "1").split(",").first.to_i)
    @non_admin = users(:two)
  end

  #--------------------------------------
  # ADMIN PATH TESTS
  #--------------------------------------

  test "admin can exchange JWT for session and access admin pages" do
    jwt = JsonWebToken.encode({ user_id: @admin.id })

    get session_exchange_path(token: jwt, redirect: "/admin/jobs")

    assert_redirected_to "/admin/jobs"
    assert_equal @admin.id, session["warden.user.user.key"][0][0]
  end

  test "non-admin cannot access admin paths" do
    jwt = JsonWebToken.encode({ user_id: @non_admin.id })

    get session_exchange_path(token: jwt, redirect: "/admin/jobs")

    assert_redirected_to root_path
    assert_equal "Access denied", flash[:alert]
  end

  test "allows access to admin stats" do
    jwt = JsonWebToken.encode({ user_id: @admin.id })

    get session_exchange_path(token: jwt, redirect: "/admin/stats")

    assert_redirected_to "/admin/stats"
  end

  test "allows access to admin users" do
    jwt = JsonWebToken.encode({ user_id: @admin.id })

    get session_exchange_path(token: jwt, redirect: "/admin/users")

    assert_redirected_to "/admin/users"
  end

  #--------------------------------------
  # AUTHENTICATED PATH TESTS
  #--------------------------------------

  test "authenticated user can access profile" do
    jwt = JsonWebToken.encode({ user_id: @non_admin.id })

    get session_exchange_path(token: jwt, redirect: "/profile")

    assert_redirected_to "/profile"
    assert_equal @non_admin.id, session["warden.user.user.key"][0][0]
  end

  test "authenticated user can access repositories" do
    jwt = JsonWebToken.encode({ user_id: @non_admin.id })

    get session_exchange_path(token: jwt, redirect: "/repositories")

    assert_redirected_to "/repositories"
  end

  #--------------------------------------
  # SECURITY TESTS
  #--------------------------------------

  test "rejects missing token" do
    get session_exchange_path(redirect: "/admin/jobs")

    assert_redirected_to root_path
    assert_equal "Authentication required", flash[:alert]
  end

  test "rejects invalid JWT" do
    get session_exchange_path(token: "invalid-jwt", redirect: "/admin/jobs")

    assert_redirected_to root_path
    assert_equal "Invalid or expired token", flash[:alert]
  end

  test "rejects expired JWT" do
    jwt = JsonWebToken.encode({ user_id: @admin.id }, exp: 1.hour.ago)

    get session_exchange_path(token: jwt, redirect: "/admin/jobs")

    assert_redirected_to root_path
    assert_equal "Invalid or expired token", flash[:alert]
  end

  test "rejects non-whitelisted redirect paths" do
    jwt = JsonWebToken.encode({ user_id: @admin.id })

    get session_exchange_path(token: jwt, redirect: "/evil/path")

    assert_redirected_to root_path
    assert_equal "Invalid redirect path", flash[:alert]
  end

  test "rejects missing redirect parameter" do
    jwt = JsonWebToken.encode({ user_id: @admin.id })

    get session_exchange_path(token: jwt)

    assert_redirected_to root_path
    assert_equal "Invalid redirect path", flash[:alert]
  end

  test "rejects non-existent user" do
    jwt = JsonWebToken.encode({ user_id: 99999 })

    get session_exchange_path(token: jwt, redirect: "/profile")

    assert_redirected_to root_path
    assert_equal "User not found", flash[:alert]
  end
end
