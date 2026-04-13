defmodule KeilaWeb.PublicFormView do
  use KeilaWeb, :view
  alias Keila.Contacts.Contact
  alias Keila.Contacts.EctoStringMap

  import KeilaWeb.PublicFormLayoutView, only: [build_styles: 1]

  @form_classes "contact-form container max-w-lg mx-auto bg-white rounded-2xl py-6 pb-10 px-6 md:py-10 md:px-10 flex flex-col gap-5 shadow-xl"

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
          render_fine_print(form)
        ]
      end
    )
  end

  defp put_style_opts(opts, form) do
    opts
    |> Keyword.put(:class, @form_classes)
    |> Keyword.put(:style, build_form_styles(form))
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
    content_tag(:h1, form.name, class: "text-3xl font-bold my-2 leading-tight")
  end

  defp render_intro(form) do
    if form.settings.intro_text do
      content_tag(:div, form.settings.intro_text, class: "text-lg opacity-80 leading-relaxed")
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
        content_tag(:div, class: "p-4 shadow-sm bg-gray-50 text-sm rounded-lg border border-gray-200 w-2/3") do
          content_tag(:label, class: "flex items-center gap-2 cursor-pointer") do
            [
              content_tag(:input, nil, type: "checkbox", class: "text-xl rounded"),
              " ",
              gettext("I am human.")
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
    content_tag(:div, class: "flex justify-start mt-2") do
      [
        content_tag(:button, form.settings.submit_label || gettext("Submit"),
          class: "px-8 py-3 rounded-xl font-semibold text-base shadow-lg hover:shadow-xl transform hover:scale-[1.02] transition-all duration-200 cursor-pointer",
          style:
            build_styles(%{
              "background-color" => form.settings.submit_bg_color,
              "color" => form.settings.submit_text_color
            })
        )
      ]
    end
  end

  defp render_fine_print(form) do
    if form.settings.fine_print do
      content_tag(
        :div,
        raw(Keila.Templates.Html.restrict(form.settings.fine_print, :limited)),
        class: "text-xs opacity-60 mt-2 leading-relaxed"
      )
    else
      []
    end
  end

  defp render_fields(form, f) do
    field_mapping = data_field_mapping(form)
    data_inputs = Phoenix.HTML.FormData.to_form(f.source.changes.data, as: "data")

    form.field_settings
    |> Enum.filter(& &1.cast)
    |> Enum.map(fn field_settings ->
      content_tag(:div, class: "flex flex-col gap-1.5") do
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

    input_class = "w-full px-4 py-3 rounded-lg border text-base transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-opacity-50"

    [
      label(f, field, for: id, class: "font-medium text-sm") do
        [
          field_settings.label || to_string(field),
          if(field_settings.required, do: "", else: [" ", content_tag(:span, gettext("(optional)"), class: "opacity-50 font-normal")])
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
              id: id
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

    label(f, field, for: id, class: "flex items-center gap-3 cursor-pointer py-1") do
      with_validation(f, field) do
        [
          checkbox(f, field, class: "rounded", name: name, id: id),
          " ",
          content_tag(:span, class: "text-sm") do
            [
              field_settings.label || "",
              if(field_settings.required, do: "", else: [" ", content_tag(:span, gettext("(optional)"), class: "opacity-50")])
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

    input_class = "w-full px-4 py-3 rounded-lg border text-base transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-opacity-50"

    options =
      for %{label: label, value: value} <- field_settings.allowed_values, do: {label, value}

    [
      label(f, field, for: id, class: "font-medium text-sm") do
        [
          field_settings.label || to_string(field),
          if(field_settings.required, do: "", else: [" ", content_tag(:span, gettext("(optional)"), class: "opacity-50 font-normal")])
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
      content_tag(:label, field_settings.label, class: "font-medium text-sm"),
      with_validation(f, field) do
        content_tag(:div, class: "flex gap-3 flex-wrap") do
          for %{label: label, value: value} <- field_settings.allowed_values do
            checked? = value in values

            content_tag(:label, class: "flex items-center gap-2 cursor-pointer text-sm") do
              [
                tag(:input,
                  name: name,
                  value: value,
                  type: "checkbox",
                  checked: checked?,
                  class: "rounded"
                ),
                label || ""
              ]
            end
          end
        end
      end
    ]
  end

  def render_form_success(form) do
    content_tag(:div, class: @form_classes, style: build_form_styles(form)) do
      [
        render_h1(form),
        render_success(form),
        render_fine_print(form)
      ]
    end
  end

  def render_form_double_opt_in_required(form, email) do
    content_tag(:div, class: @form_classes, style: build_form_styles(form)) do
      [
        render_h1(form),
        render_double_opt_in_required(form, email),
        render_fine_print(form)
      ]
    end
  end

  defp render_success(form) do
    content_tag(:div, class: "flex flex-col items-center gap-3 py-4") do
      [
        content_tag(:div, "✓",
          class: "w-16 h-16 rounded-full bg-green-100 text-green-600 flex items-center justify-center text-3xl font-bold"
        ),
        content_tag(:p, form.settings.success_text || gettext("Thank you!"), class: "text-xl font-medium text-center")
      ]
    end
  end

  defp render_double_opt_in_required(form, email) do
    case form.settings.double_opt_in_message do
      message when message not in [nil, ""] ->
        content_tag(:p, message, class: "text-lg")

      _other ->
        [
          content_tag(:div, class: "flex flex-col items-center gap-3 py-4") do
            [
              content_tag(:div, "✉",
                class: "w-16 h-16 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center text-3xl"
              ),
              content_tag(:h2, gettext("Please confirm your email"), class: "text-xl font-semibold text-center"),
              content_tag(:p, class: "text-center opacity-80") do
                gettext(
                  "We've just sent an email to %{email}. Please click the link in that email to confirm your subscription.",
                  email: email
                )
              end
            ]
          end
        ]
    end
  end

  def render_unsubscribe_form(form) do
    form_styles = build_form_styles(form)

    content_tag(:div, class: @form_classes, style: form_styles) do
      content_tag(:div, class: "flex flex-col items-center gap-3 py-4") do
        [
          content_tag(:div, "👋",
            class: "w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center text-3xl"
          ),
          content_tag(:p, gettext("You have been unsubscribed from this list."), class: "text-lg text-center")
        ]
      end
    end
  end

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
