module TimeHelpers
  def mock_time_zone_now_with datetime
    zone = mock("zone", :now => datetime)
    Time.should_receive(:zone).and_return(zone)
  end

  def time datetime_str
    Time.zone.parse datetime_str
  end

  def date year, month, day = 1
    time("#{year}-#{format_date_part(month)}-#{format_date_part(day)}")
  end

  def now
    Time.zone.now
  end

  private

  def format_date_part date_part
    date_part.to_i < 10 ? "0#{date_part}" : date_part.to_s
  end
end
