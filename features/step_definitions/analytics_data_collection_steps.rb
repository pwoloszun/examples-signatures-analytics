Given /^I have created signature "([^"]*)" using template "([^"]*)"$/ do |signature_name, template_name|
  @signature = create_signature(name: signature_name, template: @template, account: @account)
end

Given /^I have created signature "([^"]*)" using template "([^"]*)" with links:$/ do |signature_name, template_name, signature_links_data|
  @signature_links_data = signature_links_data.hashes
  token_values = {}
  @signature_links_data.each do |hash|
    token_values[hash["token"]] = "<a href='#{hash["href"]}'>#{hash["text"]}</a>"
  end
  contents = mustache_render(@template.to_html, token_values)
  @signature = create_signature(name: signature_name, contents: contents, template_id: @template.id, account: @account)
end

def create_signature params
  Signature.create!(params)
end

Given /^I have sent email with signature "([^"]*)" to "([^"]*)"$/ do |signature_name, email|
  @email = Mailme.asample(@signature.id.to_s, email)
  @email.deliver
end

When /^anyone opens email with signature "([^"]*)" (\d+) times?$/ do |signature_name, displays_count|
  displays_count.to_i.times do |i|
    step "\"#{@email.to.first}\" opens the email"
    display_impressions_counter_img
  end
end

def display_impressions_counter_img
  doc = Nokogiri::HTML(current_email.default_part_body.to_s)
  url = doc.css("#impressions-counter").first['src']
  visit(url)
end

When /^someone opens email with signature "([^"]*)"$/ do |signature_name|
  step "\"#{@email.to.first}\" opens the email"
end

When /^recipient opens email with signature "([^"]*)" and clicks links:$/ do |signature_name, table|
  step "someone opens email with signature \"#{signature_name}\""
  table.hashes.each do |clicks_data|
    link_in_email = email_link_data_by_url_name(clicks_data["token"])
    clicks_data["clicks_count"].to_i.times do |i|
      visit_with_redirect(link_in_email["href"])
    end
  end
end

def email_link_data_by_url_name url_name
  link_data = link_data_by(name: url_name)
  doc = Nokogiri::HTML(current_email.default_part_body.to_s)
  doc.css("a").detect { |link| link.text == link_data["text"] }
end

def visit_with_redirect url
  begin
    visit(url)
  rescue ActionController::RoutingError => routing_error
    # ignore: Capybara cant handle external url redirects
  end
end

def link_data_by options
  @signature_links_data.detect do |link_hash|
    if options.has_key?(:href)
      link_hash["href"] == options[:href]
    elsif options.has_key?(:name)
      link_hash["token"] == options[:name] # TODO
    else
      raise "Unknown search attribute"
    end
  end
end

Then /^signature "([^"]*)" impressions count in current month should be (\d+)$/ do |signature_name, displays_count|
  step "signature \"#{signature_name}\" impressions count in #{now.month}th month of #{now.year} should be #{displays_count}"
end

def impressions_count_by_date datetime
  signature_statistic_by_date(datetime).impressions_count
end

Then /^signature "([^"]*)" impressions count in (\d+)(?:st|nd|rd|th) month of (\d+) should be (\d+)$/ do |signature_name, month, year, displays_count|
  impressions_count_by_date(date(year, month)).should == displays_count.to_i
end

Then /^signatures "([^"]*)" links clicks should be:$/ do |signature_name, table|
  table.hashes.each do |clicks_data|
    link = link_by_name(clicks_data["token"])
    link_stat = link_statistic_by_link_and_date(link, now)
    link_stat.clicks_count.should eq(clicks_data["current_month"].to_i)
    all_clicks_count(link).should eq(clicks_data["all_time"].to_i)
  end
end

def link_by_name url_name
  @signature.reload
  href = @signature_links_data.detect { |link_data| link_data["token"] == url_name }["href"]
  @signature.links.detect { |link| link.href == href }
end

def month_range datetime
  {:created_at.gte => datetime.beginning_of_month, :created_at.lte => datetime.end_of_month}
end

Then /^someone should be redirected to "([^"]*)"$/ do |href|
  current_url.should == href
  page.driver.status_code.should == 302
end
