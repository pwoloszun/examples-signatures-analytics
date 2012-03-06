require 'spec_helper'

describe Signature do
  include Mongoid::UuidHelpers
  include Rails.application.routes.url_helpers

  it { should have_field(:name).of_type(String) }
  it { should have_field(:url).of_type(String) }
  it { should have_field(:contents).of_type(String) }
  it { should have_field(:original_contents).of_type(String) }

  it { should validate_presence_of(:name) }

  it { should have_one(:video).with_dependent(:destroy) }
  it { should have_many(:images).with_dependent(:destroy) }
  it { should have_many(:links).with_dependent(:destroy) }

  it { should belong_to(:account) }
  it { should belong_to(:template) }

  let(:link_uuid) { "abc123" }

  describe ".new" do
    let(:contents) { "<div><a href='http://test.com'>test</a></div>" }

    it "should set defaults" do
      Factory.build(:signature).uuid.should_not be_nil
    end

    it "should init links if contents attribute defined and contains some links" do
      Factory.build(:signature, contents: contents).links.should_not be_empty
    end

    it "should init links if contents attribute defined and contains some links" do
      persisted_signature = Factory.create(:signature, contents: contents)
      persisted_signature.reload
      persisted_signature.links.should_not be_empty
    end
  end

  describe "#contents=" do
    let(:contents_without_links) { "<p>some text</p><div>long paragraph...</div>" }
    let(:other_contents) { "<div>test</div>" }
    let(:signature) { Factory.build(:signature, contents: original_contents) }
    let(:new_contents) { "<p>some contents</p>" }
    let(:new_link_hrefs) { ["http://facebook.com/test", "http://twitter.com/test", "http://linkedin.com/test"] }

    context "no links in signature contents" do
      let(:original_contents) { contents_without_links }

      it "should set original_contents attribute" do
        signature.original_contents.should == original_contents
        Factory.build(:signature, contents: other_contents).original_contents.should == other_contents
      end

      it "should store original contents" do
        signature.original_contents.should == original_contents
      end

      it "should not modify original_contents" do
        signature.contents.should == original_contents
      end

      it "should not have any links" do
        signature.links.should be_empty
      end
    end

    context "signature contents contains some link" do
      let(:original_contents) { contents_without_links + links_contents(new_link_hrefs) }

      it "should set original_contents attribute" do
        signature.original_contents.should == original_contents
        Factory.build(:signature, contents: other_contents).original_contents.should == other_contents
      end

      it "should store original contents" do
        signature.original_contents.should == original_contents
      end

      it "should modify original_contents" do
        signature.contents.should_not == original_contents
      end

      it "should have as many links as defined in contents" do
        signature.links.size.should == new_link_hrefs.size
      end

      it "links should contain new link hrefs" do
        signature_links_should_include_all(new_link_hrefs)
      end

      it "contents should contain links to application" do
        contents_link_hrefs = Nokogiri::HTML(signature.contents).css("a").map { |link| link["href"] }
        application_hrefs = signature.links.map { |link| analytics_link_click_url(link) }
        contents_link_hrefs.should == application_hrefs
      end

      def analytics_link_click_url link
        analytics_signature_link_click_url(signature_uuid: signature.uuid, link_uuid: link.uuid)
      end
    end

    context "update of signature containing some links" do
      let(:original_link_hrefs) { ["http://google.pl", "http://nba.com"] }
      let(:original_contents) { contents_without_links + links_contents(original_link_hrefs) }
      let(:new_contents) { contents_without_links + links_contents(new_link_hrefs) }

      before(:each) do
        signature.contents = new_contents
      end

      it "should set original_contents attribute" do
        signature.original_contents.should == new_contents
      end

      it "should not remove links that do not exist in contents anymore" do
        signature_links_should_include_all(original_link_hrefs)
      end

      it "should add new and modified links" do
        signature_links_should_include_all(new_link_hrefs)
      end
    end

    def links_contents hrefs
      links = hrefs.map { |href| "<p><a href='#{href}'><img src='image.jpg' alt='image alt' /></a></p>" }
      links.join
    end

    def signature_links_should_include_all hrefs
      signature_link_hrefs = signature.links.map { |link| link.href }
      hrefs.each do |href|
        signature_link_hrefs.should include(href)
      end
    end
  end

  describe "#contain_link_with_uuid?" do
    subject { signature.contain_link_with_uuid?(link_uuid) }

    let(:signature) { Factory.build(:signature) }

    before(:each) do
      signature.should_receive(:link_by_uuid).with(link_uuid).and_return(found_link)
    end

    context "signature contains link with given uuid" do
      let(:found_link) { mock("link") }

      it { should be_true }
    end

    context "signature does not contain link with given uuid" do
      let(:found_link) { nil }

      it { should be_false }
    end
  end

  describe "#link_by_uuid" do
    let(:links_without_searched_link) do
      links = []
      5.times { |i| links << Factory.build(:link) }
      links
    end

    subject { signature.link_by_uuid(link_uuid) }

    let(:signature) { Factory.build(:signature, links: links) }

    context "signature contains link with given uuid" do
      let(:searched_link) { Factory.build(:link, uuid: link_uuid) }
      let(:links) { links_without_searched_link << searched_link }

      it { should == searched_link }
    end

    context "signature does not contain link with given uuid" do
      let(:links) { links_without_searched_link }

      it { should be_nil }
    end
  end

  describe "A existing signature object" do
    let(:signature) { Factory.create(:signature) }
    let(:id) { signature.id }

    it "should provide a url for the gif file" do
      signature.gif_file_url.should == "/uploads/#{id}.gif"
    end

    it "should provide a path for the gif file" do
      stub_rails_root_with("/www/app")
      signature.gif_file_path.should == "/www/app/public/uploads/#{id}.gif"
    end

    it "should provide a directory to store static images" do
      stub_rails_root_with("/www/app")
      signature.images_directory.should == "/www/app/public/images/#{id}"
    end

    def stub_rails_root_with path
      Rails.should_receive(:root).and_return(path)
    end
  end
end
