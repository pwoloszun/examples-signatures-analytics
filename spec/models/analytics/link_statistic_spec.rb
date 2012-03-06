require 'spec_helper'

describe Analytics::LinkStatistic do
  include Mongoid::TimestampsHelpers

  it { should belong_to(:link) }
  it { should have_field(:clicks_count).of_type(Integer) }
  it { should validate_presence_of(:link) }

  let(:link_stat) { Factory.build(:link_statistic) }
  let(:link) { Factory.create(:link) }

  describe ".new" do
    it "should set defaults" do
      link_stat.clicks_count.should == 0
    end
  end

  describe ".find_by_link_and_month" do
    let(:now) { Time.zone.parse("2011-04-23") }
    let(:found_stat) { Analytics::LinkStatistic.find_by_link_and_month(link, now) }

    context "link stat for current month already exists" do
      before(:each) do
        (1..12).each do |month|
          create_link_stat(date(2011, month), 22)
        end
      end

      it "should return existing link statistic" do
        found_stat.clicks_count.should == 22
        found_stat.created_at.should relate_to_same_month_as(now)
      end
    end

    context "no link stat for current month" do
      it "should create and return new link statistic" do
        found_stat.clicks_count.should == 0
        found_stat.created_at.should relate_to_same_month_as(now)
      end
    end
  end

  describe ".find_all_time_by_link" do
    let(:all_time_link_stat) { Analytics::LinkStatistic.find_all_time_by_link(link) }

    context "some statistics already exist" do
      before(:each) do
        create_link_stat(date(2010, 3), 99)
        create_link_stat(date(2010, 9), 4)
        create_link_stat(date(2011, 5), 0)
        create_link_stat(date(2011, 11), 11)
      end

      it "should return stat containing sum up all stats" do
        all_time_link_stat.clicks_count.should == 114
      end
    end

    context "no statistic for given signature" do
      it "should return stat with 0 clicks_count" do
        all_time_link_stat.clicks_count.should == 0
      end
    end
  end

  describe "#add_click" do
    let(:original_clicks_count) { 21 }

    before(:each) do
      link_stat.clicks_count = original_clicks_count
      link_stat.add_click
    end

    it "should increment clicks_count by 1" do
      link_stat.clicks_count.should == original_clicks_count + 1
    end
  end

  def create_link_stat datetime, clicks_count = 0
    Factory.create(:link_statistic, clicks_count: clicks_count, created_at: datetime, link: link)
  end
end
