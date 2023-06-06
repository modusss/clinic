require "test_helper"

module ClinicManagement
  class MessagesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get messages_index_url
      assert_response :success
    end

    test "should get new" do
      get messages_new_url
      assert_response :success
    end

    test "should get show" do
      get messages_show_url
      assert_response :success
    end

    test "should get edit" do
      get messages_edit_url
      assert_response :success
    end

    test "should get create" do
      get messages_create_url
      assert_response :success
    end

    test "should get update" do
      get messages_update_url
      assert_response :success
    end

    test "should get destroy" do
      get messages_destroy_url
      assert_response :success
    end
  end
end
