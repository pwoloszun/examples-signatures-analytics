shared_examples_for "template has not met requirements" do
  it { should_assign_template }
  it { should redirect_to(edit_admin_template_path(template)) }

  it "should add error msg" do
    error_should_include(requirements_errors.join("\n"))
  end
end
