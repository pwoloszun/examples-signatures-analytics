require 'spec_helper'

describe Template do
  it { should have_field(:name).of_type(String) }
  it { should have_field(:body).of_type(String) }
  it { should have_field(:width).of_type(Integer) }
  it { should have_field(:height).of_type(Integer) }
  it { should have_field(:hex_id).of_type(String) }
  it { should have_field(:active).of_type(Boolean).with_default_value_of(true) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:body) }
  it { should validate_presence_of(:width) }
  it { should validate_numericality_of(:width).to_allow(:only_integer => true) }
  it { should validate_presence_of(:height) }
  it { should validate_numericality_of(:height).to_allow(:only_integer => true) }
  it { should validate_presence_of(:hex_id) }

  it { should have_many(:assets).with_dependent(:destroy) }
  it { should have_many(:signatures).with_dependent(:destroy) }

  let(:template) { Factory.build(:template) }

  describe "fields with dynamic defaults" do
    it "should init hex_id field" do
      template.hex_id.should_not be_nil
    end
  end

  describe ".active" do
    let(:active_count) { 12 }
    let(:inactive_count) { 7 }
    let(:active_templates) { Template.active }

    before(:each) do
      active_count.times do |i|
        Factory.create(:template, name: "active #{i}")
      end
      inactive_count.times do |i|
        Factory.create(:template, name: "inactive #{i}", active: false)
      end
    end

    it "should return all active templates" do
      active_templates.count.should eq(active_count)
    end
  end

  describe "#body_filled_with_tokens" do
    it "TODO"
  end

  describe "#placeholder" do
    before(:each) do
      template.body = body
    end

    subject { template.placeholder }

    context "body contains placeholder" do
      let(:body) { "<h1>Hello Template!</h1>#{img_html(placeholder_url)}" }
      let(:expected_placeholder) { placeholder_url }

      it { should eq(expected_placeholder) }
    end

    context "body does not contain placeholder" do
      let(:body) { "<h1>Hello Template!</h1>" }

      it { should be_nil }
    end
  end

  describe "#placeholder_size" do
    before(:each) do
      template.body = body
    end

    subject { template.placeholder_size }

    context "body contains placeholder" do
      let(:body) { "<h1>Hello Template!</h1>#{placeholder_img(placeholder_size)}" }
      let(:placeholder_size) { "800x600" }

      it { should eq(placeholder_size) }
    end

    context "body does not contain placeholder" do
      let(:body) { "<h1>Hello Template!</h1>" }

      it { should be_nil }
    end
  end

  describe "#tokens" do
    let(:body) do
      tokens_html = ""
      tokens.each do |token|
        tokens_html += "<div><h2>{{#{token}}}</h2><p><a href='http://{{#{token}}}.com'>Hello {{#{token}}}!</a></p></div>"
      end
      "<h1>Hello Template!</h1> #{tokens_html}"
    end

    before(:each) do
      template.body = body
    end

    subject { template.tokens }

    context "body has some tokens" do
      let(:tokens) { ["test", "email", "some_token"] }

      it { should eq(tokens) }
    end

    context "body doe not have any tokens" do
      let(:tokens) { [] }

      it { should eq(tokens) }
    end
  end

  describe "#has_met_requiremets?" do
    let(:tokens) { ["name", "website"] }
    let(:tokens_html) { tokens.map { |token| "<a href='http://{{#{token}}}.com'>Welcome {{#{token}}}</a>" } }
    let(:placeholder) { placeholder_img }
    let(:img_name) { "img.jpg" }
    let(:image) { img_html(img_name) }
    let(:bg_name) { "bg.gif" }
    let(:table) { table_html(bg_name) }
    let(:assets) { [asset(name: bg_name), asset(name: img_name)] }

    let(:body) { "<h1>Hello Template!</h1> #{tokens_html} #{placeholder} #{image} #{table} #{image}" }

    before(:each) do
      template.body = body
      template.assets << assets
    end

    subject { template.has_met_requirements? }

    context "has met all requirements" do
      it { should be_true }
    end

    context "has no placeholder" do
      let(:placeholder) { nil }

      it { should be_false }
    end

    context "has invalid tokens" do
      let(:tokens) { ["invalid_token", "name", "other_invalid_token"] }

      it { should be_false }
    end

    context "does not have required assets" do
      context "has not enough assets" do
        let(:assets) { [asset(name: bg_name)] }

        it { should be_false }
      end

      context "not all images has counterparts assets" do
        let(:assets) { [asset(name: img_name), asset(name: "unknown asset")] }

        it { should be_false }
      end
    end
  end

  describe "#requiremets_errors" do
    let(:tokens) { ["name", "website"] }
    let(:tokens_html) { tokens.map { |token| "<a href='http://{{#{token}}}.com'>Welcome {{#{token}}}</a>" } }
    let(:placeholder) { placeholder_img }
    let(:img_name) { "img.jpg" }
    let(:image) { img_html(img_name) }
    let(:bg_name) { "bg.gif" }
    let(:table) { table_html(bg_name) }
    let(:assets) { [asset(name: bg_name), asset(name: img_name)] }

    let(:body) { "<h1>Hello Template!</h1> #{tokens_html} #{placeholder} #{image} #{table} #{image}" }

    before(:each) do
      template.body = body
      template.assets << assets
    end

    subject { template.requirements_errors }

    context "has met all requirements" do
      it { should be_empty }
    end

    context "has no placeholder" do
      let(:placeholder) { nil }

      it { should include(I18n.t("model.template.requirements_errors.missing_placeholder")) }
    end

    context "has invalid tokens" do
      let(:tokens) { ["name", "email"] + invalid_tokens }
      let(:invalid_tokens) { ["invalid_token", "other_invalid_token"] }

      it { should include(I18n.t("model.template.requirements_errors.invalid_tokens", invalid_tokens: invalid_tokens.join(", "))) }
    end

    context "does not have required assets" do
      context "has not enough assets" do
        let(:assets) { [] }
        let(:missing_assets) { [bg_name, img_name].join(", ") }

        it { should include(I18n.t("model.template.requirements_errors.missing_assets", missing_assets: missing_assets)) }
      end

      context "not all images has counterparts assets" do
        let(:assets) { [asset(name: img_name), asset(name: "unknown asset")] }
        let(:missing_assets) { [bg_name].join(", ") }

        it { should include(I18n.t("model.template.requirements_errors.missing_assets", missing_assets: missing_assets)) }
      end
    end
  end

  describe "#add_asset" do
    let(:assets) { [asset(filename: "01.png", name: "logo"), asset(filename: "facebook.png", name: "fb")] }

    before(:each) do
      template.assets << assets
    end

    context "asset successfully added" do
      let(:new_asset) { asset(name: asset_name, filename: "02.png") }

      context "template already has asset with same name" do
        let(:asset_name) { assets.first.name }

        it "assets should include added asset" do
          template.add_asset(new_asset)
          template.assets.should include(new_asset)
        end

        it "should be true" do
          template.add_asset(new_asset).should be_true
        end

        it "should replace existing asset with same name" do
          template.add_asset(new_asset)
          template.asset_by_name(asset_name).should eq(new_asset)
        end
      end

      context "template does not have asset of given name" do
        let(:asset_name) { "new name" }

        it "assets should include added asset" do
          template.add_asset(new_asset)
          template.assets.should include(new_asset)
        end

        it "should be true" do
          template.add_asset(new_asset).should be_true
        end
      end
    end

    context "asset failed to add" do
      let(:invalid_asset) { Asset.new(name: asset_name) }

      context "template already has asset with same name" do
        let(:asset_name) { assets.first.name }

        it "should not include invalid asset" do
          template.add_asset(invalid_asset)
          template.assets.should_not include(invalid_asset)
        end

        it "should be false" do
          template.add_asset(invalid_asset).should be_false
        end

        it "invalid asset should have some errors" do
          template.add_asset(invalid_asset)
          invalid_asset.errors.should_not be_empty
        end

        it "should include original asset with same name" do
          template.add_asset(invalid_asset)
          template.asset_by_name(asset_name).should eq(assets.first)
        end
      end

      context "template does not have asset of given name" do
        let(:asset_name) { "new name" }

        it "should not include invalid asset" do
          template.add_asset(invalid_asset)
          template.assets.should_not include(invalid_asset)
        end

        it "should be false" do
          template.add_asset(invalid_asset).should be_false
        end

        it "invalid asset should have some errors" do
          template.add_asset(invalid_asset)
          invalid_asset.errors.should_not be_empty
        end
      end
    end
  end

  describe "#all_images_names" do
    let(:backgrounds) { bg_names.map { |name| table_html(name) } }
    let(:images) { img_names.map { |name| img_html(name) } }
    let(:body) { "<h1>Hello Template!</h1> #{images} #{backgrounds}" }

    before(:each) do
      template.body = body
    end

    context "template has neither images nor backgrounds" do
      let(:bg_names) { [] }
      let(:img_names) { [] }

      it "should be empty" do
        template.all_images_names.should be_empty
      end
    end

    context "template has both images and backgrounds" do
      let(:bg_names) { ["background.jpg", "bg.gif"] }
      let(:img_names) { ["image.jpeg", "img.png"] }
      let(:expected_names) { bg_names + img_names }

      it "should include all backgrounds and images names" do
        template.all_images_names.sort.should eq(expected_names.sort)
      end
    end
  end

  describe "#has_signatures?" do
    let(:signatures) { [Factory.build(:signature)] * signatures_count }

    before(:each) do
      template.signatures << signatures
    end

    subject { template.has_signatures? }

    context "template has no signatures" do
      let(:signatures_count) { 0 }

      it { should be_false }
    end

    context "template has some signatures" do
      let(:signatures_count) { 7 }

      it { should be_true }
    end
  end

  describe "#has_images?" do
    before(:each) do
      template.body = "#{placeholder_img}#{images_html}"
    end

    subject { template.has_images? }

    context "has no images and no backgrounds" do
      let(:images_html) { "" }

      it { should be_false }
    end

    context "has some images" do
      let(:images_html) { img_html("test.jpg") }

      it { should be_true }
    end

    context "has some backgrounds" do
      let(:images_html) { table_html("test.jpg") }

      it { should be_true }
    end
  end

  describe "#create_new_version!" do
    let(:name) { "Google" }
    let(:signatures) { [Factory.build(:signature), Factory.build(:signature)] }
    let(:assets) { [asset(name: "img 0"), asset(name: "img 1")] }
    let(:template) { Factory.create(:template, name: name, assets: assets, signatures: signatures) }
    let(:new_version) { template.create_new_version!(params) }

    context "successfully created new version" do
      let(:params) { {name: "new name", width: 997, body: "#{placeholder_img}<p>{{email}}</p>"}.stringify_keys }

      it "should deactivate original template" do
        new_version
        template.should_not be_active
      end

      it "should add timestamp suffix to name" do
        new_version
        template.should_not be_active
      end

      it "should return new version" do
        new_version.should be_a(Template)
        new_version.reload
        new_version.should_not eq(template)
      end

      it "new version should be active" do
        new_version.should be_active
      end

      it "new version should be persisted" do
        new_version.reload
        new_version.should be_persisted
      end

      it "new version should have previous version attributes merged with passed attributes" do
        filter = lambda { |name, value| !name.match(/^_/) }
        expected_attributes = template.attributes.select(&filter).merge(params)
        new_version.attributes.select(&filter).should eq(expected_attributes)
      end

      it "new version should have same amount of assets" do
        new_version.assets.count.should eq(template.assets.count)
      end

      it "new version should have cloned previous version assets" do
        new_version.assets.map(&:name).should eq(template.assets.map(&:name))
        new_version.assets.map(&:file).should_not eq(template.assets.map(&:file))
        #new_version.assets.map { |asset| asset.file.url) }.should_not eq(template.assets.map(&:file))
      end

      it "new version should not have signatures" do
        new_version.should_not have_signatures
      end
    end

    context "error occurred" do
      let(:params) { {name: nil}.stringify_keys }

      it "should raise error" do
        lambda { new_version }.should raise_error
      end
    end
  end

  describe "#to_html" do
    before(:each) do
      template.body = body
    end

    context "template without any images, backgrounds, placeholders" do
      let(:body) { "<h1>Hello Template!</h1><p>{{name}} {{email}}</p>" }
      let(:expected_html) { body }

      it "should return html template representation" do
        template.to_html.should eq(expected_html)
      end
    end

    context "all images and backgrounds have uploaded assets" do
      subject { template.to_html.gsub("\n", "").gsub("\"", "'") }

      context "template has some images" do
        let(:img_name) { "image_source.jpg" }
        let(:other_img_name) { "other_image_source.gif" }
        let(:body) { "<h1>Hello Template!</h1>#{img_html(img_name)}#{img_html(other_img_name)}" }
        let(:img_asset) { asset(name: img_name) }
        let(:other_img_asset) { asset(name: other_img_name) }
        let(:expected_html) { "<h1>Hello Template!</h1>#{img_html(img_asset.file.full_url)}#{img_html(other_img_asset.file.full_url)}" }

        before(:each) do
          template.assets << [img_asset, other_img_asset]
        end

        it { should eq(expected_html) }
      end

      context "template has some backgrounds" do
        let(:bg_name) { "image_source.jpg" }
        let(:other_bg_name) { "other_image_source.gif" }
        let(:body) { "<h1>Hello Template!</h1>#{table_html(bg_name)}#{table_html(other_bg_name)}" }
        let(:bg_asset) { asset(name: bg_name) }
        let(:other_bg_asset) { asset(name: other_bg_name) }
        let(:expected_html) { "<h1>Hello Template!</h1>#{table_html(bg_asset.file.full_url)}#{table_html(other_bg_asset.file.full_url)}" }

        before(:each) do
          template.assets << [bg_asset, other_bg_asset]
        end

        it { should eq(expected_html) }
      end

      context "template has placeholder" do
        context "placeholder as image" do
          let(:body) { "<h1>Hello Template!</h1>#{img_html(placeholder_url)}" }
          let(:expected_html) { "<h1>Hello Template!</h1>#{img_html("{{animated}}")}" }

          it { should eq(expected_html) }
        end

        context "placeholder as table background" do
          let(:body) { "<h1>Hello Template!</h1>#{table_html(placeholder_url)}" }
          let(:expected_html) { "<h1>Hello Template!</h1>#{table_html("{{animated}}")}" }

          it { should eq(expected_html) }
        end
      end
    end

    context "not all images and backgrounds have uploaded assets" do
      let(:bg_name) { "image_source.jpg" }
      let(:body) { "<h1>Hello Template!</h1>#{table_html(bg_name)}" }

      it "should raise error" do
        lambda { template.to_html }.should raise_error
      end
    end
  end

  def asset params
    params = {filename: "01.png", name: "name #{SecureRandom.hex(3)}"}.merge(params)
    params[:file] = open_asset(params.delete(:filename))
    Factory.build(:asset, params)
  end

  def placeholder_img size = nil
    img_html(placeholder_url(size))
  end

  def img_html src
    "<img src='#{src}' />"
  end

  def table_html background
    "<table background='#{background}'><tr><td></td></tr></table>"
  end

  def placeholder_url size = nil
    size = "320x150" if size.nil?
    "http://placehold.it/#{size}"
  end

end
