class Signature
  include Mongoid::Document
  include Mongoid::Uuid
  include Rails.application.routes.url_helpers

  field :name, :type => String
  field :url, :type => String
  field :contents, :type => String
  field :original_contents, :type => String
  field :youtube_url, :type => String
  field :youtube_error, :type => String

  validates_presence_of :name

  has_one :video, :dependent => :destroy
  has_many :images, :dependent => :destroy
  has_many :links, :dependent => :destroy, :autosave => true

  belongs_to :account
  belongs_to :template

  before_destroy :delete_files
  after_save :ensure_links_are_connected # TODO

  def gif_file_url
    "/uploads/#{self.id}.gif"
  end

  def gif_file_full_url
    ActionController::Base.asset_host.to_s + self.gif_file_url
  end

  def gif_file_path
    File.join(Rails.root, "public#{self.gif_file_url}")
  end

  def images_directory
    File.join(Rails.root, "public/images/#{self.id}")
  end

  def contents= value
    write_attribute(:original_contents, value)
    collect_document_links
    converted_contents = convert_contents
    write_attribute(:contents, converted_contents)
  end

  def contain_link_with_uuid? link_uuid
    !link_by_uuid(link_uuid).nil?
  end

  def link_by_uuid link_uuid
    self.links.detect { |link| link.uuid == link_uuid }
  end

  private

  def delete_files
    FileUtils.rm(self.gif_file_path) if File.exists?(self.gif_file_path)
    FileUtils.rm_rf(self.images_directory) if File.exists?(self.images_directory)
  end

  def collect_document_links
    self.links << original_document.css("a").map { |link| Link.new(href: link["href"]) }
  end

  def convert_contents
    doc = original_document
    doc.css("a").each do |document_link|
      link_by_href = self.links.detect { |link| link.href == document_link["href"] }
      document_link["href"] = analytics_link_click_url(link_by_href)
    end
    doc.css("body > *").to_xhtml
  end

  def analytics_link_click_url link
    self.uuid = UUID.generate if self.uuid.nil?
    analytics_signature_link_click_url(signature_uuid: self.uuid, link_uuid: link.uuid)
  end

  def original_document
    Nokogiri::HTML(self.original_contents)
  end

  def ensure_links_are_connected
    self.links.each do |link|
      if link.signature_id.nil?
        link.signature_id = self.id
        link.save!
      end
    end
  end

end
