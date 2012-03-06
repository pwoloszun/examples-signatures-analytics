module FlashHelpers

  def notice_should_include text
    flash_should_include(:notice, text)
  end

  def error_should_include text
    flash_should_include(:error, text)
  end

  def alert_should_include text
    flash_should_include(:alert, text)
  end

  private

  def flash_should_include sym, text
    flash[sym].should include(text)
  end

end
