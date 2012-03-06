require 'spec_helper'

describe Admin::TemplatesController do
  let(:template_id) { "abc123" }
  let(:template) { mock("template") }
  let(:valid_attributes) do
    {
      :name => "Personal Trainer",
      :body => "<p>{{name}}</p>",
      :width => 200,
      :height => 100
    }
  end

  let(:templates_count) { 12 }
  let(:all_templates) do
    templates = []
    templates_count.times do |i|
      templates << Factory.create(:template)
    end
    templates
  end
  let(:all_decorated_templates) { mock("all decorated templates") }

  before(:each) do
    @template1 = all_templates.first
    basic_authenticate!
  end

  describe "GET index" do
    before(:each) do
      Template.should_receive(:all).and_return(all_templates)
      TemplateDecorator.should_receive(:decorate).with(all_templates).and_return(all_decorated_templates)
      get :index
    end

    it { should assign_to(:templates).with(all_decorated_templates) }
  end

  describe "GET show" do
    before(:each) do
      mock_finding_template_by_id
      template.should_receive(:has_met_requirements?).and_return(has_met_requirements?)
    end

    context "template has met requirements" do
      let(:has_met_requirements?) { true }

      before(:each) do
        get :show, id: template_id
      end

      it { should_assign_template }
      it { should render_template(:show) }
    end

    context "template has not met requirements" do
      let(:has_met_requirements?) { false }
      let(:requirements_errors) { ["error 0", "error 1", "error 2"] }

      before(:each) do
        template.should_receive(:requirements_errors).and_return(requirements_errors)
        get :show, id: template_id
      end

      it_should_behave_like "template has not met requirements"
    end
  end

  describe "GET new" do
    it "assigns a new template as @template" do
      get :new
      assigns(:template).should be_a_new(Template)
    end
  end

  describe "GET edit" do
    before(:each) do
      mock_finding_template_by_id
      get :edit, id: template_id
    end

    it { should_assign_template }
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Template" do
        expect {
          post :create, :template => valid_attributes
        }.to change(Template, :count).by(1)
      end

      it "assigns a newly created template as @template" do
        post :create, :template => valid_attributes
        assigns(:template).should be_a(Template)
        assigns(:template).should be_persisted
      end

      it "redirects to the created template" do
        post :create, :template => valid_attributes
        response.should redirect_to(edit_admin_template_path(Template.last))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved template as @template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Template.any_instance.stub(:save).and_return(false)
        post :create, :template => {}
        assigns(:template).should be_a_new(Template)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Template.any_instance.stub(:save).and_return(false)
        post :create, :template => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    let(:commit_param) { I18n.t("admin.templates.form.preview") }
    let(:template_params) { {id: template_id, commit: commit_param, body: "QQ!"} }

    context "Preview button has been pressed" do
      before(:each) do
        mock_finding_template_by_id
        put :update, template_params
      end

      it { should_assign_template }
      it { should redirect_to(preview_admin_template_path(template_params)) }
    end

    context "Update button has been pressed" do
      let(:template_name) { "template name" }
      let(:template_params) { {"some" => "params", "name" => template_name} }

      before(:each) do
        mock_finding_template_by_id
        template.should_receive(:has_signatures?).and_return(has_signatures?)
      end

      context "template has some signatures" do
        let(:has_signatures?) { true }
        let(:has_images?) { false }
        let(:new_template) { mock("new template") }

        before(:each) do
          template.should_receive(:create_new_version!).with(template_params).and_return(new_template)
          new_template.should_receive(:has_images?).and_return(has_images?)
          put :update, :id => template_id, :template => template_params
        end

        it { should assign_to(:template).with(new_template) }
        it { should redirect_to(admin_templates_path) }
      end

      context "template has no signatures" do
        let(:has_signatures?) { false }

        context "successfully updated" do
          before(:each) do
            template.should_receive(:update_attributes!).with(template_params)
            template.should_receive(:has_images?).and_return(has_images?)
            put :update, :id => template_id, :template => template_params
          end

          context "has no images" do
            let(:has_images?) { false }

            it { should_assign_template }
            it { should redirect_to(admin_templates_path) }
          end

          context "template has some images" do
            let(:has_images?) { true }

            it { should_assign_template }
            it { should redirect_to(edit_admin_template_path(template)) }
          end
        end

        context "validation failed - not updated" do
          let(:exception) { mock("exception") }

          before(:each) do
            template.should_receive(:update_attributes!).with(template_params).and_raise(exception)
            put :update, :id => template_id, :template => template_params
          end

          it { should_assign_template }
          it { should render_template("edit") }
        end
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested template" do
      expect {
        delete :destroy, :id => @template1.id.to_s
      }.to change(Template, :count).by(-1)
    end

    it "redirects to the templates list" do
      delete :destroy, :id => @template1.id.to_s
      response.should redirect_to(admin_templates_path)
    end
  end

  describe "GET preview" do
    let(:template_params) { {"id" => template_id, "commit" => I18n.t("admin.templates.preview.button"), "body" => "QQ!"} }

    before(:each) do
      mock_finding_template_by_id
      template.should_receive(:attributes=).with(template_params)
      template.should_receive(:has_met_requirements?).and_return(has_met_requirements?)
    end

    context "template has met requirements" do
      let(:has_met_requirements?) { true }

      before(:each) do
        get :preview, id: template_id, template: template_params
      end

      it { should_assign_template }
      it { should render_template(:preview) }
    end

    context "template has not met requirements" do
      let(:has_met_requirements?) { false }
      let(:requirements_errors) { ["error 0", "error 1", "error 2"] }

      before(:each) do
        template.should_receive(:requirements_errors).and_return(requirements_errors)
        get :preview, id: template_id, template: template_params
      end

      it_should_behave_like "template has not met requirements"
    end
  end

  describe "GET render_preview" do
    let(:template_params) { {"id" => template_id, "body" => "QQ!"} }
    let(:template_html) { mock("template html") }

    before(:each) do
      mock_finding_template_by_id
      template.should_receive(:attributes=).with(template_params)
      template.should_receive(:to_html)
      Mustache.should_receive(:render).and_return(template_html)
      get :render_preview, id: template_id, template: template_params
    end

    it { should_assign_template }
    it { should assign_to(:html_output).with(template_html) }
    it { should render_template("layouts/template") }
    it { should render_template(:render_preview) }
  end

  describe "POST add_asset" do
    let(:asset_params) { {"name" => "asset_name"} }
    let(:asset_file) { uploaded_file("steve.jpeg", "image/jpeg") }
    let(:params) { {"id" => template_id, "file" => asset_file, "asset" => asset_params} }
    let(:expected_asset_params) { asset_params.merge("file" => asset_file) }
    let(:asset) { mock("asset") }

    before(:each) do
      mock_finding_template_by_id
      Asset.should_receive(:new).with(expected_asset_params).and_return(asset)
      template.should_receive(:add_asset).with(asset).and_return(asset_successfully_added?)
    end

    context "successfully uploaded templates asset" do
      let(:asset_successfully_added?) { true }

      before(:each) do
        post :add_asset, params
      end

      it { should_assign_template }

      it "should render successfull JSON" do
        response.body.should eq({success: true}.to_json)
      end
    end

    context "error occurred while uploading templates asset" do
      let(:asset_successfully_added?) { false }
      let(:errors) { mock("errors") }
      let(:full_messages) { ["err 0", "err 1"] }

      before(:each) do
        asset.should_receive(:errors).and_return(errors)
        errors.should_receive(:full_messages).and_return(full_messages)
        post :add_asset, params
      end

      it { should_assign_template }

      it "should render first error" do
        response.body.should eq({error: full_messages.join("\n")}.to_json)
      end
    end
  end

  def basic_authenticate!
    encoded_login = Base64::encode64("#{Admin::TemplatesController::ADMIN_USER}:#{Admin::TemplatesController::ADMIN_PASS}")
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + encoded_login
  end

  def mock_finding_template_by_id
    Template.should_receive(:find).with(template_id).and_return(template)
  end

  def should_assign_template
    should assign_to(:template).with(template)
  end
end
