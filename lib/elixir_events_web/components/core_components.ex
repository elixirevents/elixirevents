defmodule ElixirEventsWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: ElixirEventsWeb.Gettext

  alias Phoenix.HTML.Form, as: HTMLForm
  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Variants

    * `"primary"` — filled purple, for main actions
    * `"ghost"` — text-only, subtle hover, for secondary actions
    * `"danger"` — filled red, for destructive actions
    * `"outline"` — bordered, for tertiary actions

  ## Sizes

    * `"sm"` — compact (default)
    * `"md"` — standard
    * `"lg"` — full-width

  ## Examples

      <.button>Save</.button>
      <.button variant="primary">Save</.button>
      <.button variant="ghost">Cancel</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled type)
  attr :class, :string, default: nil
  attr :variant, :string, values: ~w(primary ghost danger outline), default: "primary"
  attr :size, :string, values: ~w(sm md lg), default: "sm"
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    assigns =
      assign(assigns, :btn_class, [
        "inline-flex items-center justify-center gap-1.5 font-medium transition-colors rounded-lg",
        size_class(assigns.size),
        variant_class(assigns.variant),
        assigns.class
      ])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@btn_class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@btn_class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  defp variant_class("primary"),
    do: "bg-primary hover:bg-primary/85 text-primary-content font-bold"

  defp variant_class("ghost"),
    do: "text-base-content/60 hover:text-base-content hover:bg-base-300/30"

  defp variant_class("danger"),
    do: "bg-error hover:bg-error/85 text-error-content font-bold"

  defp variant_class("outline"),
    do: "border border-primary/40 text-primary hover:bg-primary/10 hover:border-primary/60"

  defp size_class("sm"), do: "px-4 py-2 text-sm"
  defp size_class("md"), do: "px-5 py-2.5 text-sm"
  defp size_class("lg"), do: "px-6 py-3 text-base w-full"

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to HTMLForm.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        HTMLForm.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {HTMLForm.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{HTMLForm.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={HTMLForm.normalize_value(@type, @value)}
          class={[
            @class ||
              "w-full input bg-base-200/50 border-base-300 focus:border-primary focus:outline-none focus:ring-0 text-base-content placeholder:text-base-content/30",
            @errors != [] && (@error_class || "input-error border-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ElixirEventsWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ElixirEventsWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a confirmation modal dialog.

  Opens with `show_modal/1` JS command, closes with cancel button or backdrop click.
  When confirmed, pushes the specified event to the LiveView.

  ## Examples

      <.confirm_modal
        id="claim-confirm"
        title="Claim this profile"
        confirm_event="claim_profile"
      >
        <p>This will submit a claim request for admin review.</p>
      </.confirm_modal>

      <button phx-click={show_modal("claim-confirm")}>Claim</button>
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :confirm_event, :string, required: true
  attr :confirm_label, :string, default: "Confirm"
  attr :cancel_label, :string, default: "Cancel"
  attr :variant, :string, values: ~w(default danger), default: "default"
  slot :inner_block, required: true

  def confirm_modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-[100] hidden"
      aria-modal="true"
      role="dialog"
      phx-mounted={JS.hide()}
    >
      <%!-- Backdrop --%>
      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
        phx-click={hide_modal(@id)}
      />
      <%!-- Panel --%>
      <div class="fixed inset-0 flex items-center justify-center p-4">
        <div
          id={"#{@id}-panel"}
          class="relative w-full max-w-md rounded-2xl bg-base-200 border border-base-300/50 shadow-2xl p-6 transform transition-all"
          phx-click-away={hide_modal(@id)}
        >
          <h3 class="font-display text-lg font-bold text-base-content">{@title}</h3>
          <div class="mt-3 text-sm text-base-content/70">
            {render_slot(@inner_block)}
          </div>
          <div class="mt-6 flex items-center justify-end gap-3">
            <%= if @confirm_event != "" do %>
              <.button variant="ghost" type="button" phx-click={hide_modal(@id)}>
                {@cancel_label}
              </.button>
              <.button
                variant={if @variant == "danger", do: "danger", else: "primary"}
                type="button"
                phx-click={hide_modal(@id) |> JS.push(@confirm_event)}
              >
                {@confirm_label}
              </.button>
            <% else %>
              <.button variant="outline" type="button" phx-click={hide_modal(@id)}>
                Got it
              </.button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc "Shows a modal by id."
  def show_modal(id) do
    JS.show(
      to: "##{id}",
      transition: {"ease-out duration-200", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-panel",
      transition:
        {"ease-out duration-200", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.focus_first(to: "##{id}-panel")
  end

  @doc "Hides a modal by id."
  def hide_modal(id) do
    JS.hide(
      to: "##{id}-backdrop",
      transition: {"ease-in duration-150", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-panel",
      transition:
        {"ease-in duration-150", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}")
  end

  @doc """
  Renders a dropdown menu.

  The trigger slot renders the element that opens the menu.
  The inner block contains the menu items.

  ## Examples

      <.dropdown id="user-menu">
        <:trigger>
          <button>Open</button>
        </:trigger>
        <.dropdown_item href="/settings">Settings</.dropdown_item>
        <.dropdown_divider />
        <.dropdown_item href="/logout" method="delete" variant="danger">Log out</.dropdown_item>
      </.dropdown>
  """
  attr :id, :string, required: true
  attr :align, :string, values: ~w(start end), default: "end"
  slot :trigger, required: true
  slot :inner_block, required: true

  def dropdown(assigns) do
    ~H"""
    <div class="dropdown" phx-click-away={close_dropdown(@id)} id={@id}>
      <div
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={toggle_dropdown(@id)}
      >
        {render_slot(@trigger)}
      </div>

      <div
        id={"#{@id}-panel"}
        class={["dropdown-panel", "dropdown-panel--#{@align}"]}
        role="menu"
        data-state="closed"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :label, :string, default: nil
  slot :inner_block

  def dropdown_label(assigns) do
    ~H"""
    <span class="dropdown-label">
      {render_slot(@inner_block) || @label}
    </span>
    """
  end

  def dropdown_divider(assigns) do
    ~H"""
    <div class="dropdown-divider" />
    """
  end

  attr :href, :string, default: nil
  attr :method, :string, default: nil
  attr :variant, :string, values: ~w(default danger), default: "default"
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_item(assigns) do
    ~H"""
    <.link
      href={@href}
      method={@method}
      class={["dropdown-item", @variant == "danger" && "dropdown-item--danger"]}
      role="menuitem"
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  A custom select component that uses the dropdown styling instead of native OS select.
  Works as a form input — stores the selected value in a hidden input.

  ## Examples

      <.custom_select
        id="platform-select"
        name="profile[social_links][0][platform]"
        value={:twitter}
        options={[{"X", :twitter}, {"GitHub", :github}]}
      />
  """
  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :options, :list, required: true
  attr :prompt, :string, default: "Select..."
  attr :form_id, :string, default: nil, doc: "the id of the parent form to trigger change on"

  def custom_select(assigns) do
    selected_label =
      Enum.find_value(assigns.options, assigns.prompt, fn
        {label, val} -> if to_string(val) == to_string(assigns.value), do: label
        val -> if to_string(val) == to_string(assigns.value), do: val
      end)

    assigns = assign(assigns, :selected_label, selected_label)

    ~H"""
    <div class="dropdown relative" phx-click-away={close_dropdown(@id)} id={@id}>
      <input type="hidden" name={@name} value={@value} id={"#{@id}-value"} />
      <button
        type="button"
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={toggle_dropdown(@id)}
        class="w-full input cursor-pointer flex items-center justify-between gap-2 text-sm"
      >
        <span class="truncate">{@selected_label}</span>
        <.icon name="hero-chevron-up-down-micro" class="size-4 opacity-40 shrink-0" />
      </button>

      <div
        id={"#{@id}-panel"}
        class={["dropdown-panel", "dropdown-panel--start", "w-full", "min-w-[10rem]"]}
        role="listbox"
        data-state="closed"
      >
        <button
          :for={{label, val} <- @options}
          type="button"
          role="option"
          aria-selected={to_string(val) == to_string(@value)}
          class={[
            "dropdown-item w-full text-left",
            to_string(val) == to_string(@value) && "dropdown-item--active"
          ]}
          phx-click={
            JS.set_attribute({"value", to_string(val)}, to: "##{@id}-value")
            |> JS.set_attribute({"data-state", "closed"}, to: "##{@id}-panel")
            |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id} [aria-haspopup]")
            |> then(fn js ->
              if @form_id,
                do: JS.dispatch(js, "change", to: "##{@form_id}"),
                else: js
            end)
          }
        >
          {label}
        </button>
      </div>
    </div>
    """
  end

  defp toggle_dropdown(id) do
    JS.toggle_attribute({"data-state", "open", "closed"}, to: "##{id}-panel")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id} [aria-haspopup]")
  end

  defp close_dropdown(id) do
    JS.set_attribute({"data-state", "closed"}, to: "##{id}-panel")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id} [aria-haspopup]")
  end
end
