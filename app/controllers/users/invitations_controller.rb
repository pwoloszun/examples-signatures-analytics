class Users::InvitationsController < Devise::InvitationsController

  before_filter :assert_user_is_account_owner
  before_filter :assert_can_invite_more_users, :only => [:new, :create]

  def new
    @resource = User.new
    @resource.account = current_user.account
  end

  def destroy
    resource = User.find(params[:id])
    if current_user.owner_of?(resource.account)
      resource.destroy
      flash[:notice] = I18n.t("plans.users_tab.notice.destroy.accomplished")
    else
      flash[:error] = I18n.t("plans.users_tab.notice.destroy.error")
    end
    redirect_to(plans_path + "#users")
  end

  private

  def assert_user_is_account_owner
    unless current_user.account_owner?
      flash[:error] = I18n.t("errors.forbidden")
      redirect_to(dashboard_path)
    end
  end

  def assert_can_invite_more_users
    if current_user.has_reached_invited_users_limit?
      flash[:alert] = I18n.t("plans.users_tab.alerts.reached_invited_users_limit")
      redirect_to(insufficient_plan_path(:id => current_user.plan.name))
    end
  end

end
