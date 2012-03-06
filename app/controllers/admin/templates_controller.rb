class Admin::TemplatesController < ApplicationController
  ADMIN_USER = "xxx"
  ADMIN_PASS = "xxx"

  before_filter :verify_admin
  before_filter :assign_template, :except => [:index, :new, :create]

  def index
    @templates = TemplateDecorator.decorate(Template.all)
  end

  def new
    @template = Template.new
    respond_to do |format|
      format.html
      format.json { render json: @template }
    end
  end

  def create
    @template = Template.new(params[:template])
    respond_to do |format|
      if @template.save
        format.html { redirect_to edit_admin_template_path(@template), notice: 'Template was successfully created.' }
        format.json { render json: @template, status: :created, location: @template }
      else
        format.html { render action: "new" }
        format.json { render json: @template.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if params[:commit] == I18n.t("admin.templates.form.preview")
      redirect_to params.merge(action: "preview")
    else
      update_template
    end
  end

  def show
    ensure_template_has_met_requirements
  end

  def preview
    @template.attributes = params[:template]
    ensure_template_has_met_requirements
  end

  def render_preview
    @template.attributes = params[:template]
    @html_output = Mustache.render(@template.to_html, TemplateForm.token_default)
    render :layout => "template"
  end

  def add_asset
    params[:asset][:file] = params[:file]
    asset = Asset.new(params[:asset])
    if @template.add_asset(asset)
      render_json({success: true})
    else
      render_json({error: asset.errors.full_messages.join("\n")})
    end
  end

  def destroy
    @template.destroy
    respond_to do |format|
      format.html { redirect_to admin_templates_path }
      format.json { head :ok }
    end
  end

  private

  def verify_admin
    authenticate_or_request_with_http_basic do |username, password|
      username == ADMIN_USER && password == ADMIN_PASS
    end
  end

  def assign_template
    @template = Template.find(params[:id])
  end

  def update_template
    begin
      if @template.has_signatures?
        @template = @template.create_new_version!(params[:template])
      else
        @template.update_attributes!(params[:template])
      end
      redirect_path = @template.has_images? ? edit_admin_template_path(@template) : admin_templates_path
      respond_to do |format|
        format.html { redirect_to redirect_path, notice: 'Template was successfully updated.' }
        format.json { head :ok }
      end
    rescue Exception => e
      respond_to do |format|
        format.html { render action: "edit", error: e.to_s }
        format.json { render json: e, status: :unprocessable_entity }
      end
    end
  end

  def render_json args
    render :text => args.to_json, :content_type => "application/json"
  end

  def ensure_template_has_met_requirements
    unless @template.has_met_requirements?
      flash[:error] = @template.requirements_errors.join("\n")
      redirect_to edit_admin_template_path(@template)
    end
  end

end

