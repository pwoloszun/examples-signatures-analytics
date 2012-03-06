require "nokogiri"
require "mustache"

class Template
  include Mongoid::Document

  field :name, :type => String
  field :body, :type => String
  field :width, :type => Integer
  field :height, :type => Integer
  field :hex_id, :type => String, default: lambda { SecureRandom.hex(3) }
  field :active, :type => Boolean, :default => true

  validates_presence_of :name, :body, :hex_id, :width, :height
  validates_numericality_of :width, :height, :only_integer => true

  has_many :assets, :dependent => :destroy
  has_many :signatures, :dependent => :destroy

  scope :active, where(active: true)

  def add_asset asset
    return false unless asset.valid?
    destroy_asset_with_same_name_if_exists(asset)
    self.assets << asset
    asset.valid?
  end

  def asset_by_name name
    self.assets.detect { |asset| asset.name == name }
  end

  def placeholder
    @placeholder ||= find_placeholder_in(IMG_HOLDER) || find_placeholder_in(BG_HOLDER)
  end

  def placeholder_size
    placeholder =~ /placehold\.it\/(.+)/
    $1
  end

  def tokens
    all_tokens = Mustache::Parser.new.compile(self.body)
    all_tokens.inject([]) do |mustache_tokens, token|
      mustache_tokens << token[2][2][0] if token[0] == :mustache # [:mustache, :etag, [:mustache, :fetch, ["name"]]]
      mustache_tokens
    end.uniq
  end

  def has_met_requirements?
    has_placeholder? && has_valid_tokens? && has_required_assets?
  end

  def requirements_errors
    @requirements_errors = []
    @requirements_errors << requirements_error_msg(:missing_placeholder) unless has_placeholder?
    @requirements_errors << requirements_error_msg(:invalid_tokens, invalid_tokens: invalid_tokens.join(", ")) unless has_valid_tokens?
    @requirements_errors << requirements_error_msg(:missing_assets, missing_assets: missing_assets_names.join(", ")) unless has_required_assets?
    @requirements_errors
  end

  def all_images_names
    @all_images_names ||= (backgrounds_names + images_names).uniq
  end

  def has_images?
    all_images_names.any?
  end

  def to_html
    replace_all_images_with_assets!
    doc.to_xhtml(indent: 0).gsub(/%7B%7B(.+?)%7D%7D/, '{{\1}}') # replace mustache {{ and }} with %7B%7B and %7D%7D
  end

  def has_signatures?
    self.signatures.any?
  end

  def create_new_version! params
    new_params = new_version_params(params)
    deactivate!
    new_template = Template.new(new_params)
    new_template.assets = self.assets.map { |asset| asset.clone_with_file }
    new_template.save!
    new_template
  end

  private

  PLACEHOLDER_REGEXP = /placehold/
  BG_HOLDER = {tag: "table, td", attribute: "background"}
  IMG_HOLDER = {tag: "img", attribute: "src"}
  ALL_IMAGES_HOLDERS = [IMG_HOLDER, BG_HOLDER]

  def replace_all_images_with_assets!
    ALL_IMAGES_HOLDERS.each do |img_holder|
      replace_images_with_assets_for img_holder
    end
  end

  def find_placeholder_in img_holder
    attr = img_holder[:attribute]
    tag_with_placeholder = doc.search(img_holder[:tag]).detect do |tag|
      tag.has_attribute?(attr) && tag[attr].match(PLACEHOLDER_REGEXP)
    end
    tag_with_placeholder.nil? ? nil : tag_with_placeholder[attr]
  end

  def images_to_assets
    if @images_to_assets.nil?
      @images_to_assets = {placeholder => "{{animated}}"}
      all_images_names.each { |name| @images_to_assets[name] = asset_url(name) }
    end
    @images_to_assets
  end

  def asset_url name
    asset_by_name(name).file.full_url
  end

  def replace_images_with_assets_for img_holder
    attr = img_holder[:attribute]
    doc.search(img_holder[:tag]).each do |tag|
      if tag.has_attribute?(attr)
        tag[attr] = images_to_assets[tag[attr]]
      end
    end
  end

  def new_version_params params
    new_params = self.attributes.select { |name, value| !name.match(/^_/) }
    new_params.merge(params.select { |name, value| name.to_s != "id" })
  end

  def doc
    @doc ||= Nokogiri::HTML.fragment(self.body) # we use fragment to avoid doctype, body and html surrounding tags
  end

  def backgrounds_names
    attributes_values_in(BG_HOLDER)
  end

  def images_names
    attributes_values_in(IMG_HOLDER)
  end

  def attributes_values_in img_holder
    attr = img_holder[:attribute]
    doc.search(img_holder[:tag]).inject([]) do |attributes_values, tag|
      if tag.has_attribute?(attr)
        attribute_value = tag[attr]
        attributes_values << attribute_value unless attribute_value.match(PLACEHOLDER_REGEXP)
      end
      attributes_values
    end
  end

  def has_placeholder?
    !placeholder.nil?
  end

  def has_valid_tokens?
    invalid_tokens.empty?
  end

  def invalid_tokens
    tokens.find_all { |token| !TemplateForm::VALID_TOKENS.include?(token) }
  end

  def has_required_assets?
    missing_assets_names.empty?
  end

  def requirements_error_msg suffix, params = {}
    I18n.t("model.template.requirements_errors.#{suffix}", params)
  end

  def missing_assets_names
    all_images_names.select { |name| asset_by_name(name).nil? }
  end

  def deactivate!
    timestamp = Time.zone.now.to_s(:number)
    self.update_attributes!(name: "#{self.name}_#{timestamp}", active: false)
  end

  def destroy_asset_with_same_name_if_exists asset
    asset_with_same_name = asset_by_name(asset.name)
    unless asset_with_same_name.nil?
      asset_with_same_name.destroy
      self.assets.delete(asset_with_same_name)
    end
  end

end
