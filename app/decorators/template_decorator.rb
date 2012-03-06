class TemplateDecorator < ApplicationDecorator
  decorates :template

  def new_button
    button :new, class: "primary"
  end

  def show_button
    h.link_to(button_label(:show), template_path, button_params)
  end

  def preview_button
    button :preview
  end

  def edit_button
    button :edit
  end

  def destroy_button
    modal_id = "confirm-template-destroy-#{template.id}"
    params = {
      modal_id: modal_id,
      message: destroy_message,
      control_button: h.link_to(button_label(:destroy), "#null", class: "btn", "data-controls-modal" => modal_id, "data-backdrop" => "true"),
      confirm_button: h.link_to(button_label(:confirm_destroy), template_path, button_params(method: :delete))
    }
    modal_confirm(params)
  end

  private

  def button name, params = {}
    h.link_to(button_label(name), button_link(name), button_params(params))
  end

  def button_label name
    I18n.t("admin.templates.list.#{name}")
  end

  def button_link name
    h.send(:"#{name}_admin_template_path", template)
  end

  def template_path
    h.admin_template_path(template)
  end

  def button_params params = {}
    params.merge(class: "btn #{params[:class]}")
  end

  def modal_confirm params
    h.render_cell(:modal, :confirm, params)
  end

  def destroy_message
    if template.signatures.empty?
      I18n.t("admin.templates.list.destroy_warnings.default", template_name: template.name)
    else
      I18n.t("admin.templates.list.destroy_warnings.used_by_signatures", template_name: template.name, signatures_count: template.signatures.count)
    end
  end

end
