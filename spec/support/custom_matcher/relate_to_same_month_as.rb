RSpec::Matchers.define :relate_to_same_month_as do |expected|
  match do |actual|
    actual.year == expected.year && actual.month == expected.month
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have same year and month as #{expected}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would have same year and month as #{expected}"
  end

  description do
    "relate to same year and month as #{expected}"
  end
end
