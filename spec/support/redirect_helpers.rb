module RedirectHelpers

  def should_render_nothing
    response.body.should be_blank
  end

  def should_redirect_to_dashboard
    should redirect_to(dashboard_path)
  end

  def should_redirect_to url
    should redirect_to(url)
  end

end
