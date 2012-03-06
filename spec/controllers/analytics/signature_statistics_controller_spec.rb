require 'spec_helper'

describe Analytics::SignatureStatisticsController do
  let(:signature_id) { "123" }
  let(:signature) { mock("signature") }
  let(:now) { mock("now") }
  let(:current_month_stats) { mock("current month impressions") }

  describe "GET 'add_impression'" do
    before(:each) do
      Signature.should_receive(:find).with(signature_id).and_return(signature)
    end

    context "passed id of existing signature" do
      let(:successfully_saved?) { true }

      before(:each) do
        mock_time_zone_now_with now
        Analytics::SignatureStatistic.should_receive(:find_by_signature_and_month).with(signature, now).and_return(current_month_stats)
        current_month_stats.should_receive(:add_impression)
        current_month_stats.should_receive(:save).and_return(successfully_saved?)
        get :add_impression, :signature_id => signature_id
      end

      it "should render nothing" do
        should_render_nothing
      end
    end

    context "passed unknown signature id" do
      let(:signature) { nil }

      before(:each) do
        get :add_impression, :signature_id => signature_id
      end

      it "should render nothing" do
        should_render_nothing
      end
    end
  end

  describe "GET 'link_click'" do
    let(:signature_uuid) { "abc123xyz" }
    let(:link_uuid) { "efg987fff" }
    let(:href) { "http://google.pl" }
    let(:link) { mock("link") }

    before(:each) do
      Signature.should_receive(:first).with(conditions: {uuid: signature_uuid}).and_return(signature)
      signature.should_receive(:contain_link_with_uuid?).with(link_uuid).and_return(contain_link_with_uuid?)
    end

    context "signature contains link" do
      let(:contain_link_with_uuid?) { true }
      let(:current_month_link_stat) { mock("link stat") }

      before(:each) do
        signature.should_receive(:link_by_uuid).with(link_uuid).and_return(link)
        mock_time_zone_now_with(now)
        Analytics::LinkStatistic.should_receive(:find_by_link_and_month).with(link, now).and_return(current_month_link_stat)
        current_month_link_stat.should_receive(:add_click)
        current_month_link_stat.should_receive(:save)
        link.should_receive(:href).and_return(href)
        get :link_click, signature_uuid: signature_uuid, link_uuid: link_uuid
      end

      it { should assign_to(:signature).with(signature) }

      it "should redirect to link href" do
        should_redirect_to(href)
      end
    end

    context "signature does not contain link" do
      let(:contain_link_with_uuid?) { false }

      before(:each) do
        get :link_click, signature_uuid: signature_uuid, link_uuid: link_uuid
      end

      it { should assign_to(:signature).with(signature) }

      it "should render nothing" do
        should_render_nothing
      end
    end
  end

  describe "GET 'show'" do
    include LoggedInUserContext

    before(:each) do
      Signature.should_receive(:find).with(signature_id).and_return(signature)
      current_user.should_receive(:has_access_to?).with(signature).and_return(has_access_to_signature)
    end

    context "user has access to signature" do
      let(:has_access_to_signature) { true }
      let(:all_time_stats) { mock("all time stats") }
      let(:links_count) { 0 }

      let(:links) { mocks_list("link") }
      let(:current_month_links_stats) { mocks_list("current month link stat") }
      let(:all_time_links_stats) { mocks_list("current month link stat") }
      let(:all_links_data) do
        data = {}
        links.each_with_index do |link, i|
          data[link] = {current_month: current_month_links_stats[i], all_time: all_time_links_stats[i]}
        end
        data
      end

      before(:each) do
        mock_time_zone_now_with now
        should_fetch_signature_stats
        should_fetch_links_stats
        get :show, signature_id: signature_id
      end

      it { should assign_to(:current_month_statistics).with(current_month_stats) }
      it { should assign_to(:all_time_statistics).with(all_time_stats) }
      it { should render_template(:show) }

      context "signature has some links" do
        let(:links_count) { 5 }

        it { should assign_to(:all_links_data).with(all_links_data) }
      end

      context "signature has no links" do
        let(:links_count) { 0 }

        it { should assign_to(:all_links_data).with(all_links_data) }
      end

      def should_fetch_signature_stats
        Analytics::SignatureStatistic.should_receive(:find_by_signature_and_month).with(signature, now).and_return(current_month_stats)
        Analytics::SignatureStatistic.should_receive(:find_all_time_by_signature).with(signature).and_return(all_time_stats)
      end

      def should_fetch_links_stats
        signature.should_receive(:links).and_return(links)
        links.each_with_index do |link, i|
          Analytics::LinkStatistic.should_receive(:find_by_link_and_month).with(link, now).and_return(current_month_links_stats[i])
          Analytics::LinkStatistic.should_receive(:find_all_time_by_link).with(link).and_return(all_time_links_stats[i])
        end
      end

      def mocks_list name
        list = []
        links_count.times do |i|
          list << mock("#{name} #{i}")
        end
        list
      end
    end

    context "user does not have access to signature" do
      let(:has_access_to_signature) { false }

      before(:each) do
        get :show, signature_id: signature_id
      end

      it "should add error msg" do
        error_should_include(I18n.t("analytics.signatures.errors.no_access"))
      end

      it { should_redirect_to_dashboard }
    end
  end
end
