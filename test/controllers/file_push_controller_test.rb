# frozen_string_literal: true

require "test_helper"

class FilePushControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
  end

  teardown do
    @luca = users(:luca)
    sign_out @luca
  end

  test "New push form is NOT available anonymous" do
    get new_file_push_path
    assert_redirected_to new_user_session_path
  end

  test '"active" and "expired" should redirect anonymous to user sign in' do
    get active_file_pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")

    get expired_file_pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get active_file_pushes_path
    assert_response :success
    assert response.body.include?("You currently have no active file pushes.")

    get expired_file_pushes_path
    assert_response :success
    assert response.body.include?("You currently have no expired file pushes.")
  end

  test "logged in users with pushes can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get new_file_push_path
    assert_response :success
    assert response.body.include?("You can upload up to")

    post file_pushes_path params: {
      file_push: {
        payload: "TWVycnkgQ2hyaXN0bWFzIDIwMjIgdG8gbXkgYmVhdXRpZnVsIGdpcmxzIExlYSAmIEdpdWxpYW5hLiAgSSBsb3ZlIHlvdS4gIFBhcGE="
      }
    }
    assert_response :redirect

    get active_file_pushes_path
    assert_response :success
    assert_not response.body.include?("You currently have no active password pushes.")
  end

  test "get active dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get active_file_pushes_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get expired_file_pushes_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "override base url" do
    Settings.override_base_url = "https://example.com:12345"

    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    post file_pushes_path params: {
      file_push: {
        payload: "TWVycnkgQ2hyaXN0bWFzIDIwMjIgdG8gbXkgYmVhdXRpZnVsIGdpcmxzIExlYSAmIEdpdWxpYW5hLg=="
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    assert response.body.include?("https://example.com:12345")
  end
end
