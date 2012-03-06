require 'spec_helper'

describe Users::InvitationsController do
  include LoggedInUserContext

  before(:each) do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  context "current user is account owner" do
    before(:each) do
      should_assert_user_is_account_owner(true)
    end

    describe "GET new" do
      let(:user) { mock("user") }

      before(:each) do
        should_assert_can_invite_more_users(has_reached_invited_users_limit)
      end

      context "can invite more users" do
        let(:has_reached_invited_users_limit) { false }

        before(:each) do
          User.should_receive(:new).and_return(user)
          user.should_receive(:account=).with(current_user.account)
          get(:new)
        end

        it { should assign_to(:resource).with(user) }
        it { should render_template(:new) }
      end

      context "can not invite more users" do
        let(:has_reached_invited_users_limit) { true }

        before(:each) do
          get(:new)
        end

        it "should display error" do
          alert_should_include(I18n.t("plans.users_tab.alerts.reached_invited_users_limit"))
        end
        it { should redirect_to(insufficient_plan_path(:id => current_user.plan.name)) }
      end
    end

    describe "DELETE destroy" do
      let(:id) { "123" }
      let(:user) { mock("user", :account => account) }

      before(:each) do
        current_user.should_receive(:owner_of?).with(account).and_return(owner_of)
        User.should_receive(:find).with(id).and_return(user)
      end

      context "current user is owner of deleting user account" do
        let(:owner_of) { true }

        before(:each) do
          user.should_receive(:destroy)
          delete(:destroy, :id => id)
        end

        it "notice should contain accomplished msg" do
          notice_should_include(I18n.t("plans.users_tab.notice.destroy.accomplished"))
        end

        it { should_redirect_to_settings_users_tab }
      end

      context "current user is not owner of deleting user account" do
        let(:owner_of) { false }

        before(:each) do
          delete(:destroy, :id => id)
        end

        it "notice should contain error msg" do
          error_should_include(I18n.t("plans.users_tab.notice.destroy.error"))
        end

        it { should_redirect_to_settings_users_tab }
      end

      def should_redirect_to_settings_users_tab
        should redirect_to(plans_path + "#users")
      end
    end
  end

  context "current user is not account owner" do
    before(:each) do
      should_assert_user_is_account_owner(false)
    end

    describe "GET new" do
      before(:each) do
        get(:new)
      end

      it { should_redirect_to_dashboard }
    end

    describe "DELETE destroy" do
      let(:id) { "123" }

      before(:each) do
        delete(:destroy, :id => id)
      end

      it { should_redirect_to_dashboard }
    end
  end

  def should_assert_user_is_account_owner account_owner
    current_user.should_receive(:account_owner?).and_return(account_owner)
  end

  def should_assert_can_invite_more_users reached_invited_users_limit
    current_user.should_receive(:has_reached_invited_users_limit?).and_return(reached_invited_users_limit)
  end

end
