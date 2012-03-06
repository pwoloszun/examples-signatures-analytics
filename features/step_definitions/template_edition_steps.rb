When /^I click (Edit|Preview|Show) "([^"]*)" template button$/ do |action, template_name|
  template = template_by_name(template_name)
  within(templates_row_selector_for(template)) do
    step %{I follow "#{I18n.t("admin.templates.list.#{action.downcase}")}"}
  end
end

When /^I modify template fields:$/ do |table|
  @modified_template_data = table.hashes
  table.hashes.each do |field_data|
    label = I18n.t("admin.templates.form.#{field_data["label"]}")
    value = field_data["value"]
    step %{I fill in "#{label}" with "#{value}"}
  end
end

When /^I press (\w+) template button$/ do |button_text|
  step %{I press "#{I18n.t("admin.templates.form.#{button_text.downcase}")}"}
end

When /^I press Edit button$/ do
  step %{I follow "#{I18n.t("admin.templates.preview.edit")}"}
end

Then /^I should be on "([^"]*)" template edit page$/ do |template_name|
  template = template_by_name(template_name)
  step %{I should be on "#{edit_admin_template_path(template)}"}
end

Then /^I should see list of images to upload containing:$/ do |table|
  table.hashes.each do |image_data|
    within("div[rel='images-to-upload']") do
      step %{I should see "#{image_data["name"]}"}
    end
  end
end

Then /^I should see template fields filled with:$/ do |table|
  table.hashes.each do |field_data|
    label = I18n.t("admin.templates.form.#{field_data["label"]}")
    value = field_data["value"]
    step %{the "#{label}" field should contain "#{value}"}
  end
end

Then /^I should be on "([^"]*)" template preview page$/ do |template_name|
  template = template_by_name(template_name)
  step %{I should be on "#{preview_admin_template_path(template)}"}
end

Then /^I should see following template requirements errors:$/ do |table|
  table.hashes.each do |error_data|
    code = error_data["requirements_error_code"]
    params = eval(error_data["params"])
    step %{I should see "#{I18n.t("model.template.requirements_errors.#{code}", params)}"}
  end
end

Then /^I should see modified "([^"]*)" template preview$/ do |template_name|
  template = template_by_name(template_name)
  step %{I should see "#{template.name}"}
  iframe = find("div[rel='template-preview'] iframe")
  visit(iframe["src"])
  html = mustache_render_defaults(modified_template("body"))
  texts_from(html).each do |text|
    page.should have_content(text)
  end
end

Then /^template "([^"]*)" should have (\d+) signatures?$/ do |template_name, signatures_count|
  template = template_by_name(template_name)
  template.signatures.count.should eq(signatures_count.to_i)
end

def texts_from html
  Nokogiri::HTML(html).children[1].children[0].children.map { |node| node.text } # TODO
end

def modified_template label
  @modified_template_data.detect { |field_data| field_data["label"] == label }["value"]
end
