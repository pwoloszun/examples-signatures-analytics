class ModalCell < Cell::Rails

  include ActionView::Helpers::UrlHelper

  def confirm args
    @modal_id = args[:modal_id] || raise("undefined mandatory :modal_id argument")
    @control_button = args[:control_button] || raise("undefined mandatory :control_button argument")
    @confirm_button = args[:confirm_button] || default_confirm_button
    @cancel_button = args[:cancel_button] || default_cancel_button
    @message = args[:message] || default_message
    @title = args[:title] || default_title
    render
  end

  private

  def default_title
    confirm_default_text("title")
  end

  def default_message
    confirm_default_text("message")
  end

  def default_confirm_button
    link_to(confirm_default_text("confirm"), "#null", class: "btn btn-primary")
  end

  def default_cancel_button
    link_to(confirm_default_text("cancel"), "#null", class: "btn close", "data-dismiss" => "modal")
  end

  def confirm_default_text suffix
    I18n.t("cells.modal.confirm.default.#{suffix}")
  end

end
