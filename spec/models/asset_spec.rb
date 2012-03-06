require 'spec_helper'

describe Asset do
  let(:template) { Factory(:template) }
  let(:asset) { new_asset }
  let(:asset_pathname) { pathname(asset) }

  it { should have_field(:name).of_type(String) }
  it { should have_field(:file).of_type(Mongoid::Fields::Serializable::Object) }
  it { should belong_to(:template) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:file) }
  it { should validate_uniqueness_of(:name).scoped_to(:template_id) }

  describe "#save" do
    after(:each) do
      asset_pathname.delete
    end

    it "should store file on disk" do
      asset.save!
      asset_pathname.should exist
    end
  end

  describe "#destroy" do
    before(:each) do
      asset.save!
    end

    it "should remove file linked with asset" do
      asset.destroy
      asset_pathname.should_not exist
    end
  end

  describe "#clone_with_file" do
    let(:clone) { asset.clone_with_file }

    it "should have same name as original" do
      clone.name.should eq(asset.name)
    end

    it "should have same filename as original" do
      clone.filename.should eq(asset.filename)
    end

    it "should not have same file url as original" do
      clone.file.url.should_not eq(asset.file.url)
    end

    it "should have file with same content as original" do
      file_content(clone).should eq(file_content(asset))
    end
  end

  def new_asset
    Factory.build(:asset, :template => template)
  end

  def pathname asset
    Pathname.new(asset.file.current_path)
  end

  def file_content asset
    File.read(asset.file.current_path)
  end

end
