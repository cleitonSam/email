defmodule KeilaWeb.PublicFormView do
  use KeilaWeb, :view
  alias Keila.Contacts.Contact
  alias Keila.Contacts.EctoStringMap

  import KeilaWeb.PublicFormLayoutView, only: [build_styles: 1]

  @form_classes "contact-form container max-w-md mx-auto bg-white rounded-3xl py-8 pb-10 px-7 md:py-10 md:px-10 flex flex-col gap-6"

  defp input_styles(form) do
    build_styles(%{
      "background-color" => form.settings.input_bg_color,
      "color" => form.settings.input_text_color,
      "border-color" => form.settings.input_border_color
    })
  end

  def render_form(form, changeset \\ Ecto.Changeset.change(%Contact{}), mode) do
    form_opts =
      []
      |> put_style_opts(form)
      |> maybe_put_csrf_opt(form, mode)

    form_for(
      changeset,
      Routes.public_form_url(KeilaWeb.Endpoint, :submit, form.id),
      form_opts,
      fn f ->
        [
          render_h1(form),
          render_intro(form),
          render_fields(form, f),
          render_honeypot(form),
          render_captcha(form, mode, f),
          render_submit(form, f),
          render_fine_print(form),
          render_branding()
        ]
      end
    )
  end

  defp put_style_opts(opts, form) do
    opts
    |> Keyword.put(:class, @form_classes)
    |> Keyword.put(:style, build_form_styles(form))
    |> Keyword.put(:id, "fluxo-form")
  end

  defp maybe_put_csrf_opt(opts, form, mode) do
    csrf_disabled? = mode == :embed or form.settings.csrf_disabled

    if csrf_disabled? do
      Keyword.put(opts, :csrf_token, false)
    else
      opts
    end
  end

  defp build_form_styles(form) do
    build_styles(%{
      "background-color" => form.settings.form_bg_color,
      "color" => form.settings.text_color
    })
  end

  defp render_h1(form) do
    content_tag(:h1, form.name, class: "text-2xl md:text-3xl font-extrabold leading-tight tracking-tight")
  end

  defp render_intro(form) do
    if form.settings.intro_text do
      content_tag(:p, form.settings.intro_text, class: "text-base opacity-65 leading-relaxed -mt-2")
    else
      []
    end
  end

  @honeypot_field_name "h[url]"
  defp render_honeypot(_form) do
    [
      tag(:input,
        aria_hidden: "true",
        name: @honeypot_field_name,
        style: "display: none",
        autocomplete: "off",
        novalidate: true
      )
    ]
  end

  defp render_captcha(form, mode, f) do
    cond do
      form.settings.captcha_required and mode == :preview ->
        content_tag(:div, class: "captcha-box p-3.5 bg-gray-50 text-sm rounded-xl border border-gray-200/80 w-auto inline-flex") do
          content_tag(:label, class: "flex items-center gap-2.5 cursor-pointer select-none") do
            [
              content_tag(:input, nil, type: "checkbox", class: "w-5 h-5 rounded-md border-2 border-gray-300"),
              content_tag(:span, gettext("I am human."), class: "text-gray-600")
            ]
          end
        end

      form.settings.captcha_required ->
        content_tag(:div, class: "flex flex-col") do
          with_validation(f, :captcha) do
            KeilaWeb.Captcha.captcha_tag()
          end
        end

      true ->
        []
    end
  end

  defp render_submit(form, _f) do
    submit_bg = form.settings.submit_bg_color || "#0066FF"

    content_tag(:div, class: "flex flex-col gap-3.5 mt-1") do
      [
        content_tag(:button,
          [
            content_tag(:span, form.settings.submit_label || gettext("Submit"), class: "btn-text"),
            content_tag(:span, "", class: "btn-loader hidden")
          ],
          class: "fluxo-submit-btn w-full py-4 rounded-2xl font-bold text-base tracking-wide cursor-pointer relative overflow-hidden",
          style:
            build_styles(%{
              "background-color" => submit_bg,
              "color" => form.settings.submit_text_color
            }),
          onclick: "this.classList.add('is-loading')"
        ),
        content_tag(:p, class: "flex items-center justify-center gap-1.5 text-xs opacity-35 select-none") do
          [
            {:safe, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"11\" height=\"11\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"3\" y=\"11\" width=\"18\" height=\"11\" rx=\"2\" ry=\"2\"></rect><path d=\"M7 11V7a5 5 0 0 1 10 0v4\"></path></svg>"},
            gettext("Your data is safe and secure.")
          ]
        end
      ]
    end
  end

  defp render_fine_print(form) do
    if form.settings.fine_print do
      content_tag(
        :div,
        raw(Keila.Templates.Html.restrict(form.settings.fine_print, :limited)),
        class: "text-xs opacity-45 leading-relaxed"
      )
    else
      []
    end
  end

  defp render_branding do
    content_tag(:div, class: "flex items-center justify-center gap-1.5 pt-2 opacity-25 hover:opacity-50 transition-opacity") do
      content_tag(:a, [
        {:safe, "<svg width=\"12\" height=\"12\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\"><path d=\"M13 2L3 14h9l-1 8 10-12h-9l1-8z\"/></svg>"},
        content_tag(:span, "Fluxo Email MKT", class: "text-[10px] font-medium tracking-wide")
      ],
        href: "https://fluxodigitaltech.com.br",
        target: "_blank",
        rel: "noopener",
        class: "flex items-center gap-1 no-underline"
      )
    end
  end

  defp render_fields(form, f) do
    field_mapping = data_field_mapping(form)
    data_inputs = Phoenix.HTML.FormData.to_form(f.source.changes.data, as: "data")

    form.field_settings
    |> Enum.filter(& &1.cast)
    |> Enum.map(fn field_settings ->
      content_tag(:div, class: "fluxo-field flex flex-col gap-1.5") do
        if field_settings.field == :data do
          atom_key = find_mapping_atom_key(field_mapping, field_settings.key)
          render_field(form, data_inputs, atom_key, field_settings)
        else
          render_field(form, f, field_settings.field, field_settings)
        end
      end
    end)
  end

  defp render_field(form, f, field, field_settings = %{type: type})
       when type in [:string, :email, :integer] or field in [:email, :first_name, :last_name] do
    name = form_input_name(f, field_settings)
    id = form_input_id(f, field_settings)
    input_styles = input_styles(form)

    input_class = "fluxo-input w-full px-4 py-3.5 rounded-xl border-2 text-base transition-all duration-200 focus:outline-none focus:ring-0 placeholder-gray-400/50"

    [
      label(f, field, for: id, class: "font-semibold text-sm tracking-wide") do
        [
          field_settings.label || to_string(field),
          if(field_settings.required, do: content_tag(:span, " *", class: "opacity-30"), else: [" ", content_tag(:span, gettext("(optional)"), class: "opacity-35 font-normal text-xs")])
        ]
      end,
      with_validation(f, field) do
        cond do
          field == :email or type == :email ->
            email_input(f, field,
              placeholder: field_settings.placeholder || "seu@email.com",
              style: input_styles,
              class: input_class,
              name: name,
              id: id,
              autocomplete: "email"
            )

          type == :integer ->
            number_input(f, field,
              placeholder: field_settings.placeholder,
              style: input_styles,
              class: input_class,
              step: "1",
              name: name,
              id: id
            )

          true ->
            text_input(f, field,
              placeholder: field_settings.placeholder,
              style: input_styles,
              class: input_class,
              name: name,
              id: id
            )
        end
      end
    ]
  end

  defp render_field(_form, f, field, field_settings = %{type: type}) when type in [:boolean] do
    name = form_input_name(f, field_settings)
    id = form_input_id(f, field_settings)

    label(f, field, for: id, class: "fluxo-checkbox flex items-start gap-3 cursor-pointer py-2 group") do
      with_validation(f, field) do
        [
          checkbox(f, field, class: "w-5 h-5 rounded-md border-2 border-gray-300 mt-0.5 flex-shrink-0 transition-colors", name: name, id: id),
          " ",
          content_tag(:span, class: "text-sm leading-snug select-none group-hover:opacity-80 transition-opacity") do
            [
              field_settings.label || "",
              if(field_settings.required, do: content_tag(:span, " *", class: "opacity-30"), else: [" ", content_tag(:span, gettext("(optional)"), class: "opacity-35 text-xs")])
            ]
          end
        ]
      end
    end
  end

  defp render_field(form, f, field, field_settings = %{type: :enum}) do
    name = form_input_name(f, field_settings)
    id = form_input_id(f, field_settings)
    input_styles = input_styles(form)

    input_class = "fluxo-input w-full px-4 py-3.5 rounded-xl border-2 text-base transition-all duration-200 focus:outline-none focus:ring-0 appearance-none bg-no-repeat"

    options =
      for %{label: label, value: value} <- field_settings.allowed_values, do: {label, value}

    [
      label(f, field, for: id, class: "font-semibold text-sm tracking-wide") do
        [
          field_settings.label || to_string(field),
          if(field_settings.required, do: content_tag(:span, " *", class: "opacity-30"), else: [" ", content_tag(:span, gettext("(optional)"), class: "opacity-35 font-normal text-xs")])
        ]
      end,
      with_validation(f, field) do
        select(f, field, options,
          placeholder: field_settings.placeholder,
          style: input_styles,
          class: input_class,
          name: name,
          id: id
        )
      end
    ]
  end

  defp render_field(_form, f, field, field_settings = %{type: :tags}) do
    name = form_input_name(f, field_settings) <> "[]"
    values = Ecto.Changeset.get_field(f.source, field, [])

    [
      content_tag(:label, field_settings.label, class: "font-semibold text-sm tracking-wide"),
      with_validation(f, field) do
        content_tag(:div, class: "flex gap-2 flex-wrap") do
          for %{label: label, value: value} <- field_settings.allowed_values do
            checked? = value in values

            content_tag(:label, class: "fluxo-tag inline-flex items-center gap-2 cursor-pointer text-sm px-4 py-2.5 rounded-xl border-2 border-gray-200 hover:border-gray-300 transition-all select-none") do
              [
                tag(:input,
                  name: name,
                  value: value,
                  type: "checkbox",
                  checked: checked?,
                  class: "w-4 h-4 rounded border-gray-300 hidden"
                ),
                label || ""
              ]
            end
          end
        end
      end
    ]
  end

  # ── SUCCESS STATE ──────────────────────────────────────────────
  def render_form_success(form) do
    content_tag(:div, class: "#{@form_classes} items-center", style: build_form_styles(form), id: "fluxo-form-success") do
      [
        content_tag(:div, class: "flex flex-col items-center gap-5 py-6 w-full") do
          [
            # Animated check circle
            content_tag(:div, class: "success-icon relative") do
              [
                content_tag(:div, "",
                  class: "w-24 h-24 rounded-full absolute inset-0 animate-success-ring",
                  style: "background-color: #{form.settings.submit_bg_color || "#0066FF"}10"
                ),
                content_tag(:div, class: "w-24 h-24 rounded-full flex items-center justify-center relative",
                  style: "background-color: #{form.settings.submit_bg_color || "#0066FF"}15") do
                  {:safe, "<svg class=\"animate-success-check\" xmlns=\"http://www.w3.org/2000/svg\" width=\"42\" height=\"42\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"#{form.settings.submit_bg_color || "#0066FF"}\" stroke-width=\"2.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><polyline points=\"20 6 9 17 4 12\"></polyline></svg>"}
                end
              ]
            end,
            content_tag(:h2, form.settings.success_text || gettext("Thank you!"), class: "text-2xl font-extrabold text-center mt-1"),
            content_tag(:p, gettext("You have been successfully subscribed."), class: "text-base opacity-55 text-center -mt-1")
          ]
        end,
        render_fine_print(form),
        # Confetti container
        {:safe, "<div class=\"confetti-container\" aria-hidden=\"true\"></div>"}
      ]
    end
  end

  # ── DOUBLE OPT-IN STATE ────────────────────────────────────────
  def render_form_double_opt_in_required(form, email) do
    content_tag(:div, class: "#{@form_classes} items-center", style: build_form_styles(form)) do
      [
        content_tag(:div, class: "flex flex-col items-center gap-5 py-6 w-full") do
          case form.settings.double_opt_in_message do
            message when message not in [nil, ""] ->
              [
                content_tag(:div, class: "w-24 h-24 rounded-full flex items-center justify-center animate-float",
                  style: "background-color: #{form.settings.submit_bg_color || "#0066FF"}12") do
                  {:safe, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"40\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"#{form.settings.submit_bg_color || "#0066FF"}\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z\"></path><polyline points=\"22,6 12,13 2,6\"></polyline></svg>"}
                end,
                content_tag(:p, message, class: "text-lg text-center font-medium")
              ]

            _other ->
              [
                content_tag(:div, class: "w-24 h-24 rounded-full flex items-center justify-center animate-float",
                  style: "background-color: #{form.settings.submit_bg_color || "#0066FF"}12") do
                  {:safe, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"40\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"#{form.settings.submit_bg_color || "#0066FF"}\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z\"></path><polyline points=\"22,6 12,13 2,6\"></polyline></svg>"}
                end,
                content_tag(:h2, gettext("Check your inbox"), class: "text-2xl font-extrabold text-center mt-1"),
                content_tag(:p, class: "text-base opacity-55 text-center leading-relaxed max-w-xs") do
                  gettext(
                    "We sent a confirmation to %{email}. Click the link to complete your subscription.",
                    email: email
                  )
                end,
                content_tag(:div, class: "flex items-center gap-2 mt-2 px-4 py-2.5 bg-gray-100 rounded-xl") do
                  [
                    {:safe, "<svg width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" opacity=\"0.4\"><path d=\"M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z\"/></svg>"},
                    content_tag(:span, gettext("Check your spam folder too"), class: "text-xs opacity-40")
                  ]
                end
              ]
          end
        end,
        render_fine_print(form)
      ]
    end
  end

  # ── UNSUBSCRIBE STATE ──────────────────────────────────────────
  def render_unsubscribe_form(form) do
    form_styles = build_form_styles(form)

    content_tag(:div, class: "#{@form_classes} items-center", style: form_styles) do
      content_tag(:div, class: "flex flex-col items-center gap-4 py-6") do
        [
          content_tag(:div, class: "w-24 h-24 rounded-full bg-gray-100 flex items-center justify-center") do
            {:safe, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"40\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"#9ca3af\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M18 6L6 18\"></path><path d=\"M6 6l12 12\"></path></svg>"}
          end,
          content_tag(:h2, gettext("You've been unsubscribed"), class: "text-2xl font-extrabold text-center"),
          content_tag(:p, gettext("You will no longer receive emails from this list."), class: "text-base opacity-55 text-center")
        ]
      end
    end
  end

  # ── HELPERS ────────────────────────────────────────────────────

  defp data_field_mapping(form) do
    form.field_settings
    |> Enum.filter(&(&1.field == :data))
    |> Enum.map(&EctoStringMap.FieldDefinition.from_field_settings/1)
    |> EctoStringMap.build_field_mapping()
  end

  defp find_mapping_atom_key(field_mapping, string_key) do
    Enum.find_value(field_mapping, fn
      {atom_key, %{key: ^string_key}} -> atom_key
      _other -> nil
    end)
  end

  defp form_input_name(f, field_settings) do
    case field_settings.field do
      :data ->
        "contact[data][#{field_settings.key}]"

      other ->
        Phoenix.HTML.Form.input_name(f, other)
    end
  end

  defp form_input_id(f, field_settings) do
    case field_settings.field do
      :data ->
        "contact_data_#{field_settings.key}"

      other ->
        Phoenix.HTML.Form.input_id(f, other)
    end
  end
end
