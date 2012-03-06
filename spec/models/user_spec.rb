require 'spec_helper'

describe User do

  it { should have_field(:name).of_type(String) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:email) }

  it { should belong_to(:owned_account).of_type(Account).as_inverse_of(:owner) }
  it { should belong_to(:account) }

  let(:account) { Factory.build(:account) }
  let(:user) { User.new(:account => account) }

  describe "#plan" do
    let(:plan) { mock("plan") }

    it "should delegate it to account" do
      user.account.should_receive(:plan).and_return(plan)
      user.plan.should == plan
    end
  end

  describe "#has_reached_signatures_limit?" do
    it "should delegate it to account" do
      user.account.should_receive(:has_reached_signatures_limit?).and_return(true)
      user.should have_reached_signatures_limit
    end
  end

  describe "#account_owner?" do
    it "should be false if owned account undefined" do
      user.should_not be_account_owner
    end

    it "should be true if owned account defined" do
      user.owned_account = account
      user.should be_account_owner
    end
  end

  describe "#owner_of?" do
    let(:other_account) { Factory.build(:account, :name => "other account") }

    it "should be false if user is not account owner" do
      user.should_not be_owner_of(account)
    end

    it "should be false if user owns other account" do
      user.owned_account = account
      user.should_not be_owner_of(other_account)
    end

    it "should be true if user owns given account" do
      user.owned_account = account
      user.should be_owner_of(account)
    end
  end

  describe "#has_access_to?" do
    let(:signature) { mock("signature") }

    it "should delegate it to account" do
      user.account.should_receive(:has_access_to?).with(signature).and_return(true)
      user.should have_access_to(signature)
    end
  end

end
