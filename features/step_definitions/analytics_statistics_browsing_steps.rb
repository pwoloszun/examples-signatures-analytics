Given /^email with signature "([^"]*)" has been opened (\d+) times? in (\d+)(?:st|nd|rd|th) month of (\d+)$/ do |signature_name, impressions_count, month, year|
  create_signature_statistic(created_at: date(year, month), impressions_count: impressions_count.to_i)
end

Given /^link "([^"]*)" signature "([^"]*)" links, has been clicked:$/ do |link_name, signature_name, table|
  link = link_by_name(link_name)
  table.hashes.each do |hash|
    create_link_statistic(link: link, created_at: date(hash["year"], hash["month"]), clicks_count: hash["clicks_count"].to_i)
  end
end

def create_link_statistic params
  Analytics::LinkStatistic.create!(params)
end

When /^I enter signature "([^"]*)" statistics page$/ do |signature_name|
  visit(analytics_show_signature_statistics_path(signature_id: @signature.id))
end

When /^I click signature "([^"]*)" statistics button$/ do |signature_name|
  within("tr[rel='#{signature_name}']") do
    click_link(I18n.t("signatures.index.actions.statistics"))
  end
end

Then /^I should be on signature "([^"]*)" statistics page$/ do |signature_name|
  step "I should be on \"#{analytics_show_signature_statistics_path(signature_id: @signature.id)}\""
end

Then /^signature current month impressions count should be (\d+)$/ do |impressions_count|
  stat = signature_statistic_by_date(now)
  step "I should see \"#{I18n.t("analytics.signatures.current_month.impressions", impressions_count: stat.impressions_count)}\""
end

Then /^signature all time impressions count should be (\d+)$/ do |impressions_count|
  step "I should see \"#{I18n.t("analytics.signatures.all_time.impressions", impressions_count: all_impressions_count)}\""
end

Then /^signature "([^"]*)" impressions count should be:$/ do |signature_name, impressions_table|
  step "I enter signature \"#{signature_name}\" statistics page"
  impressions_stats = impressions_table.rows_hash
  step "signature current month impressions count should be #{impressions_stats["current_month"]}"
  step "signature all time impressions count should be #{impressions_stats["all_time"]}"
end

def signature_statistic_by_date datetime
  stat = Analytics::SignatureStatistic.first(conditions: {signature_id: @signature.id}.merge(month_range(datetime)))
  stat || create_signature_statistic(created_at: datetime)
end

def create_signature_statistic params
  params[:created_at] = params[:created_at].beginning_of_month
  params[:signature] = @signature
  Analytics::SignatureStatistic.create!(params)
end

def all_impressions_count
  all_signature_stats = Analytics::SignatureStatistic.all_of(signature_id: @signature.id).to_a
  all_signature_stats.inject(0) { |sum, stat| sum + stat.impressions_count }
end

Then /^I should see signatures statistics title$/ do
  step "I should see \"#{I18n.t("analytics.signatures.show.title", name: @signature.name)}\""
end

Then /^I should see links statistics table containing:$/ do |table|
  step "I should see \"#{I18n.t("analytics.signatures.show.links.clicks_statistics")}\""
  table.hashes.each do |hash|
    link = link_by_name(hash["link_name"])
    link_stat = link_statistic_by_link_and_date(link, now)
    within("tr[rel='link_#{link.id}']") do
      step "I should see \"#{link.href}\""
      step "I should see \"#{link_stat.clicks_count}\""
      step "I should see \"#{all_clicks_count(link_stat.link)}\""
    end
  end
end

def link_statistic_by_link_and_date link, datetime
  link_stat = Analytics::LinkStatistic.first(conditions: {link_id: link.id}.merge(month_range(datetime)))
  link_stat || create_link_statistic(link: link, created_at: datetime)
end

def all_clicks_count link
  all_links_stats = Analytics::LinkStatistic.all_of(link_id: link.id).to_a
  all_links_stats.inject(0) { |sum, link_stat| sum + link_stat.clicks_count }
end
