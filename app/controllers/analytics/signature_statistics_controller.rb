class Analytics::SignatureStatisticsController < ApplicationController

  before_filter :authenticate_user!, :only => [:show]
  before_filter :assign_signature
  before_filter :assert_user_has_access_to_signature, :only => [:show]

  def add_impression
    unless @signature.nil?
      signature_stat_by_month = Analytics::SignatureStatistic.find_by_signature_and_month(@signature, now)
      signature_stat_by_month.add_impression
      signature_stat_by_month.save
    end
    render :nothing => true
  end

  def link_click
    if @signature.contain_link_with_uuid?(params[:link_uuid])
      link = @signature.link_by_uuid(params[:link_uuid])
      link_stat = Analytics::LinkStatistic.find_by_link_and_month(link, now)
      link_stat.add_click
      link_stat.save
      redirect_to link.href
    else
      render :nothing => true
    end
  end

  def show
    @current_month_statistics = Analytics::SignatureStatistic.find_by_signature_and_month(@signature, now)
    @all_time_statistics = Analytics::SignatureStatistic.find_all_time_by_signature(@signature)
    @all_links_data = {}
    @signature.links.each do |link|
      @all_links_data[link] = {
        current_month: Analytics::LinkStatistic.find_by_link_and_month(link, now),
        all_time: Analytics::LinkStatistic.find_all_time_by_link(link)
      }
    end
  end

  private

  def now
    @now ||= Time.zone.now
  end

  def assign_signature
    @signature = params[:signature_id].nil? ? signature_by_uuid : signature_by_id
  end

  def assert_user_has_access_to_signature
    unless current_user.has_access_to?(@signature)
      flash[:error] = I18n.t("analytics.signatures.errors.no_access")
      redirect_to(dashboard_path)
    end
  end

  def signature_by_id
    Signature.find(params[:signature_id])
  end

  def signature_by_uuid
    Signature.first(conditions: {uuid: params[:signature_uuid]})
  end

end
