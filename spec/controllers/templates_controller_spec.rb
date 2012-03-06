require 'spec_helper'

describe TemplatesController do
  include LoggedInUserContext

  let(:template) { Factory.create(:template, :name=>"template", :body =>"<p>{{name}}</p>") }

  describe "GET index" do
    let(:all_templates) do
      templates = []
      20.times do |i|
        templates << Factory.create(:template, :name=>"template #{i}", :body =>"<p>#{i}</p>")
      end
      templates
    end

    before(:each) do
      Template.should_receive(:active).and_return(all_templates)
      get(:index)
    end

    it { should assign_to(:templates).with(all_templates) }
  end

  describe "GET show" do
    before(:each) do
      get(:show, :id => template.id)
    end

    it { should_assign_template }
  end

  describe "GET preview" do
    before(:each) do
      get(:preview, :id => template.id)
    end

    it { should_assign_template }
    it { should assign_to(:output).with("<p>John Travolta</p>") }
  end

  def should_assign_template
    should assign_to(:template).with(template)
  end

end
