class Asset
  include Mongoid::Document

  field :name, :type => String
  mount_uploader :file, AssetUploader

  belongs_to :template

  validates_presence_of :name, :file
  validates_uniqueness_of :name, :scope => :template_id

  before_destroy :delete_file

  def clone_with_file
    clone = self.clone
    clone.file = open_file
    clone
  end

  def filename
    file.nil? ? nil : file.url[/[^\/]*$/]
  end

  private

  def delete_file
    path = self.file.path
    FileUtils.rm(path) if !path.nil? and File.exists?(path)
  end

  def open_file
    File.open(Rails.public_path.+ self.file.url)
  end

end
