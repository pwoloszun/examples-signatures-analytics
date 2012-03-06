require 'spec_helper'

describe Analytics::SignatureStatistic do
  include Mongoid::TimestampsHelpers

  it { should belong_to(:signature) }
  it { should have_many(:link_statistics) }

  it { should validate_presence_of(:signature) }

  it { should have_field(:impressions_count).of_type(Integer) }

  let(:signature) { Factory.create(:signature) }

  describe ".find_by_signature_and_month" do
    let(:now) { Time.zone.parse("2011-04-23") }
    let(:found_stat) { Analytics::SignatureStatistic.find_by_signature_and_month(signature, now) }

    context "signature stat for current month already exists" do
      before(:each) do
        (1..12).each do |month|
          create_signature_stat(date(2011, month), 10)
        end
      end

      it "should return existing signature statistic" do
        found_stat.impressions_count.should == 10
        found_stat.created_at.should relate_to_same_month_as(now)
      end
    end

    context "no signature stat for current month" do
      it "should create and return new signature statistic" do
        found_stat.impressions_count.should == 0
        found_stat.created_at.should relate_to_same_month_as(now)
      end
    end
  end

  describe ".find_all_time_by_signature" do
    let(:all_time_stat) { Analytics::SignatureStatistic.find_all_time_by_signature signature }

    context "some statistics already exist" do
      before(:each) do
        create_signature_stat(date(2010, 3), 22)
        create_signature_stat(date(2010, 9), 4)
        create_signature_stat(date(2011, 5), 0)
        create_signature_stat(date(2011, 11), 2)
      end

      it "should return stat containing sum up all stats" do
        all_time_stat.impressions_count.should == 28
      end
    end

    context "no statistic for given signature" do
      it "should return stat containing zeros" do
        all_time_stat.impressions_count.should == 0
      end
    end
  end

  describe "#add_impression" do
    let(:initial_impressions_count) { 22 }
    let(:signature_statistic) { Factory.build(:signature_statistic, impressions_count: initial_impressions_count) }

    it "should increase impressions cont by 1" do
      signature_statistic.add_impression
      signature_statistic.impressions_count.should == (initial_impressions_count + 1)
    end
  end

  def create_signature_stat datetime, impressions_count = 0
    Factory.create(:signature_statistic, impressions_count: impressions_count, created_at: datetime, signature_id: signature.id)
  end
end
