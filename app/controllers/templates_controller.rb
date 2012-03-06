class TemplatesController < ApplicationController

  before_filter :authenticate_user!

  def index
    @templates = Template.active
    respond_to do |format|
      format.html
      format.json { render json: @templates }
    end
  end

  def show
    @template = Template.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @template }
    end
  end

  def preview
    @template = Template.find(params[:id])
    @output = Mustache.render(@template.to_html, TemplateForm.token_default)
    render :inline => @output, :layout => false
  end

end

