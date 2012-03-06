module MustacheHelpers

  def mustache_render html, token_values
    Mustache.render(html, token_values)
  end

  def mustache_render_defaults html
    mustache_render(html, TemplateForm.token_default)
  end

end
