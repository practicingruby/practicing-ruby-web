require_relative '../test_helper'

class SharedArticleTest < ActionDispatch::IntegrationTest
  setup do
    @authorization = FactoryGirl.create(:authorization)
    @user          = @authorization.user
    @article       = FactoryGirl.create(:article)

    @share = SharedArticle.find_or_create_by_article_id_and_user_id(
      @article.id, @user.id)
  end

  test "shared article visible without logging in" do
    assert_article_visible(:guest)
  end

  test "shared article visit without logging in (draft)" do
    @article.update_attribute(:status, "draft")

    assert_article_visible(:guest)
  end

  test "shared article visible to logged in users" do
    sign_user_in

    assert_article_visible(:subscriber)
  end

  test "shared article visible to logged in users (draft)" do
    @article.update_attribute(:status, "draft")

    sign_user_in

    assert_article_visible(:subscriber)
  end

  test "requesting invalid share key causes a 404 response" do
    visit shared_article_path("notarealkey")

    assert_equal 404, page.status_code
  end

  def assert_article_visible(state)
    visit shared_article_path(@share.secret)

    assert_equal 200, page.status_code

    assert_current_path Rails.application.routes.url_helpers.article_path(@article)
    assert_url_has_param "u", @share.user.share_token

    case state
    when :guest
      assert_content("subscribe")
      assert_content("log in")
    when :subscriber
      assert_content("Sign out")
      assert_content("Share your thoughts:")
    else
      raise ArgumentError, "Invalid state: #{state}"
    end
  end
end
