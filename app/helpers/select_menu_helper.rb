module SelectMenuHelper
  def select_menu_field(name, label = nil, options = nil, prefix: nil, icon: nil, value: nil, id: nil, required: false)
    if options.nil?
      options = label || []
      label = nil
    end

    id = id || name
    label = label.presence || name.to_s.titleize
    required = CoerceBoolean.from(required)
    required_class = required ? "mdc-select--required" : ""

    if prefix.present?
      name = "#{prefix}[#{name}]"
      id = "#{prefix}_#{id}"
    end

    content_tag(
      :div,
      id: "#{id}-wrapper",
      class: "mdc-select mdc-select--filled #{icon.present? ? "mdc-select--with-leading-icon" : ""} #{required_class} themed",
      data: {
        controller: "select-menu",
        target: "select-menu.select"
      }
    ) do
      [
        text_field_tag(name, value.presence, type: :hidden, data: { target: "select-menu.input" }),
        content_tag(
          :div,
          class:"mdc-select__anchor w-100",
          role: "button",
          "aria-haspopup": :listbox,
          "aria-expanded": false,
          "aria-labelledby": "#{id}-label #{id}-text",
          "aria-required": required
        ) do
          [
            content_tag(:span, "", class: "mdc-select__ripple"),

            content_tag(:span, label, id: "#{id}-label", class: "mdc-floating-label"),

            content_tag(:span, class: "mdc-select__selected-text-container") do
              content_tag(:span, id: "#{id}-text", class: "mdc-select__selected-text", data: { target: "select-menu.text"}) do
                opt = options.find do |opt|
                  opt&.is_a?(Hash) ? (opt[:value] == value) : (opt == value)
                end

                opt&.is_a?(Hash) ? opt[:label] || opt[:value] : opt
              end
            end,

            content_tag(:span, class: "mdc-select__dropdown-icon") do
              <<-HTML.html_safe
                <svg
                class="mdc-select__dropdown-icon-graphic"
                viewBox="7 10 10 5" focusable="false">
                  <polygon
                      class="mdc-select__dropdown-icon-inactive"
                      stroke="none"
                      fill-rule="evenodd"
                      points="7 10 12 15 17 10">
                  </polygon>
                  <polygon
                      class="mdc-select__dropdown-icon-active"
                      stroke="none"
                      fill-rule="evenodd"
                      points="7 15 12 10 17 15">
                  </polygon>
                </svg>
              HTML
            end,

            content_tag(:span, "", class: "mdc-line-ripple")
          ].join("").html_safe

        end,

        content_tag(:div, class: "mdc-select__menu mdc-menu mdc-menu-surface mdc-menu-surface--full-width") do
          content_tag(
            :ul,
            class: "mdc-list",
            role: "listbox",
            "aria-label": "#{label} listbox"
          ) do
            [
              content_tag(
                :li,
                class: "mdc-list-item #{value.nil? ? "mdc-list-item--selected" : ""}",
                role: :option,
                data: { value: "", target: "select-menu.item" },
                "aria-selected": value.nil?
              ) do
                content_tag(:span, "", class: "mdc-list-item__ripple")
              end,

              *options.map do |opt|
                value = opt.is_a?(Hash) ? opt[:value] : opt
                label = opt.is_a?(Hash) ? opt[:label] || opt[:value] : opt
                selected = opt == value

                content_tag(
                  :li,
                  class: "mdc-list-item #{selected ? "mdc-list-item--selected" : ""}",
                  role: :option,
                  data: { value: value, target: "select-menu.item" },
                  "aria-selected": selected,
                ) do
                  [
                    content_tag(:span, "", class: "mdc-list-item__ripple"),

                    content_tag(:span, label, class: "mdc-list-item__text")
                  ].join("").html_safe
                end
              end
            ].join("").html_safe
          end
        end
      ].join("").html_safe
    end
  end
end
