defmodule ElixirEventsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ElixirEventsWeb, :html

  import ElixirEventsWeb.BrandComponents
  import ElixirEventsWeb.Helpers, only: [initials: 1, avatar_style: 1]

  alias ElixirEvents.Profiles

  embed_templates "layouts/*"

  attr :current_scope, :map, default: nil

  def site_nav(assigns) do
    ~H"""
    <nav class="sticky top-0 z-50 backdrop-blur-xl bg-base-100/80 border-b border-base-300/40">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <a href="/" class="flex items-center gap-2.5 group">
            <.potion_icon class="h-8 w-auto shrink-0" id="nav-potion" />
            <span class="font-display font-bold text-lg tracking-tight">
              Elixir<span class="text-primary">Events</span>
            </span>
          </a>
          <div class="hidden md:flex items-center gap-1">
            <a
              href="/events"
              class="px-3 py-2 text-sm font-medium text-base-content/60 hover:text-base-content transition-colors"
            >
              Events
            </a>
            <a
              href="/speakers"
              class="px-3 py-2 text-sm font-medium text-base-content/60 hover:text-base-content transition-colors"
            >
              Speakers
            </a>
            <a
              href="/talks"
              class="px-3 py-2 text-sm font-medium text-base-content/60 hover:text-base-content transition-colors"
            >
              Talks
            </a>
            <a
              href="/topics"
              class="px-3 py-2 text-sm font-medium text-base-content/60 hover:text-base-content transition-colors"
            >
              Topics
            </a>
          </div>
          <div class="flex items-center gap-3">
            <.theme_toggle />
            <button
              class="md:hidden flex items-center justify-center p-2 rounded-lg text-base-content/60 hover:text-base-content hover:bg-base-200/50 transition-colors"
              aria-label="Open menu"
              aria-expanded="false"
              onclick="
                const menu = document.getElementById('mobile-menu');
                const expanded = this.getAttribute('aria-expanded') === 'true';
                menu.classList.toggle('hidden');
                this.setAttribute('aria-expanded', !expanded);
              "
            >
              <svg
                class="h-5 w-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
              </svg>
            </button>
            <%!-- User menu --%>
            <div :if={@current_scope} class="hidden md:block">
              <.user_menu current_scope={@current_scope} />
            </div>
            <div :if={!@current_scope} class="hidden md:flex items-center gap-1">
              <a
                href="/login"
                class="px-3 py-2 text-sm font-medium text-base-content/60 hover:text-base-content transition-colors"
              >
                Sign in
              </a>
              <a
                href="/join"
                class="px-3 py-2 text-sm font-medium text-base-content/60 hover:text-base-content transition-colors"
              >
                Register
              </a>
            </div>
            <a
              href="https://github.com/elixirevents/elixirevents"
              class="hidden md:inline-flex btn btn-sm btn-primary gap-1.5"
              target="_blank"
              rel="noopener"
            >
              <.github_icon /> GitHub
            </a>
          </div>
        </div>
      </div>
      <%!-- Mobile menu --%>
      <div
        id="mobile-menu"
        class="hidden md:hidden border-t border-base-300/40 bg-base-100/95 backdrop-blur-xl"
      >
        <div class="px-4 py-3 space-y-1">
          <a
            href="/events"
            class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
          >
            Events
          </a>
          <a
            href="/speakers"
            class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
          >
            Speakers
          </a>
          <a
            href="/talks"
            class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
          >
            Talks
          </a>
          <a
            href="/topics"
            class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
          >
            Topics
          </a>
          <div class="border-t border-base-300/30 mt-2 pt-2">
            <a
              href="https://github.com/elixirevents/elixirevents"
              class="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
              target="_blank"
              rel="noopener"
            >
              <.github_icon /> GitHub
            </a>
          </div>
          <%!-- Mobile auth links --%>
          <div :if={@current_scope} class="border-t border-base-300/30 mt-2 pt-2">
            <% profile = get_user_profile(@current_scope.user) %>
            <a
              :if={profile}
              href={~p"/account/profile"}
              class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
            >
              Edit Profile
            </a>
            <a
              href={~p"/account/security"}
              class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
            >
              Account
            </a>
            <.link
              href="/logout"
              method="delete"
              class="block px-3 py-2 rounded-lg text-sm font-medium text-error/70 hover:text-error hover:bg-error/5 transition-colors"
            >
              Log out
            </.link>
          </div>
          <div :if={!@current_scope} class="border-t border-base-300/30 mt-2 pt-2">
            <a
              href="/login"
              class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
            >
              Sign in
            </a>
            <a
              href="/join"
              class="block px-3 py-2 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-200/50 transition-colors"
            >
              Register
            </a>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  def site_footer(assigns) do
    ~H"""
    <footer class="py-12 border-t border-base-300/40">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-8">
          <div class="flex items-center gap-2.5">
            <.potion_icon class="h-6 w-auto opacity-50" id="footer-potion" />
            <span class="font-display font-bold text-sm text-base-content/50">ElixirEvents</span>
          </div>
          <div class="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-base-content/50">
            <a href="/about" class="hover:text-base-content transition-colors">About</a>
            <a href="/contribute" class="hover:text-base-content transition-colors">Contribute</a>
            <a
              href="https://github.com/elixirevents/elixirevents"
              class="hover:text-base-content transition-colors"
              target="_blank"
              rel="noopener"
            >
              GitHub
            </a>
            <a
              href="https://elixirforum.com"
              class="hover:text-base-content transition-colors"
              target="_blank"
              rel="noopener"
            >
              Elixir Forum
            </a>
            <a
              href="https://discord.gg/elixir"
              class="hover:text-base-content transition-colors"
              target="_blank"
              rel="noopener"
            >
              Discord
            </a>
            <a
              href="https://elixir-lang.slack.com"
              class="hover:text-base-content transition-colors"
              target="_blank"
              rel="noopener"
            >
              Slack
            </a>
          </div>
        </div>
        <div class="mt-8 pt-6 border-t border-base-300/30 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-xs text-base-content/45">
          <p>
            Made with <.sparkle class="inline h-3 w-3 text-primary/50 -mt-0.5" />
            for the BEAM community
          </p>
          <p>elixirevents.org</p>
        </div>
      </div>
    </footer>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block

  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex flex-col">
      <.site_nav current_scope={assigns[:current_scope]} />
      <main class="flex-1 py-12 sm:py-16">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {if assigns[:inner_content], do: @inner_content, else: render_slot(@inner_block)}
        </div>
      </main>
      <.site_footer />
    </div>
    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="System theme"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Light theme"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Dark theme"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  # ── Admin layout ──────────────────────────────────────────

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block

  def admin(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex flex-col">
      <.site_nav current_scope={assigns[:current_scope]} />
      <div class="flex flex-1">
        <.admin_sidebar current_path={assigns[:current_path]} />
        <main class="flex-1 min-w-0 py-10 sm:py-12 px-6 sm:px-10 lg:px-14">
          {if assigns[:inner_content], do: @inner_content, else: render_slot(@inner_block)}
        </main>
      </div>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  attr :current_path, :string, default: nil

  defp admin_sidebar(assigns) do
    ~H"""
    <aside class="ee-admin-sidebar">
      <div class="ee-admin-sidebar-inner">
        <div class="ee-admin-sidebar-header">
          <.icon name="hero-shield-check-solid" class="size-5 text-primary" />
          <span class="font-display font-bold text-sm tracking-tight">Admin</span>
        </div>

        <nav class="ee-admin-nav">
          <div class="ee-admin-nav-section">
            <span class="ee-admin-nav-label">Manage</span>
            <.admin_nav_link
              href="/admin/claims"
              icon="hero-hand-raised"
              label="Claims"
              active={active_admin_path?(@current_path, "/admin/claims")}
            />
          </div>
        </nav>

        <div class="ee-admin-sidebar-footer">
          <a
            href="/"
            class="ee-admin-nav-link"
          >
            <.icon name="hero-arrow-left" class="size-4" />
            <span>Back to site</span>
          </a>
        </div>
      </div>
    </aside>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp admin_nav_link(assigns) do
    ~H"""
    <a href={@href} class={["ee-admin-nav-link", @active && "ee-admin-nav-link--active"]}>
      <.icon name={@icon} class="size-4" />
      <span>{@label}</span>
    </a>
    """
  end

  defp active_admin_path?(nil, _prefix), do: false
  defp active_admin_path?(current_path, prefix), do: String.starts_with?(current_path, prefix)

  # ── User menu (top bar dropdown) ──────────────────────────

  attr :current_scope, :map, required: true

  defp user_menu(assigns) do
    assigns = assign(assigns, :profile, get_user_profile(assigns.current_scope.user))

    ~H"""
    <.dropdown id="user-menu">
      <:trigger>
        <button class="ee-avatar-trigger" title={@current_scope.user.email}>
          <img
            :if={@profile && @profile.avatar_url}
            src={@profile.avatar_url}
            alt={@profile.name}
          />
          <span
            :if={!@profile || !@profile.avatar_url}
            class="flex items-center justify-center w-full h-full rounded-full font-display"
            style={
              if @profile,
                do: avatar_style(@profile.name),
                else: "background: oklch(68% 0.17 310); color: oklch(15% 0.05 310);"
            }
          >
            {if @profile,
              do: initials(@profile.name),
              else: String.first(@current_scope.user.email) |> String.upcase()}
          </span>
        </button>
      </:trigger>
      <.dropdown_item :if={@profile} href={~p"/account/profile"}>
        <.icon name="hero-pencil-square-micro" class="size-4" /> Edit Profile
      </.dropdown_item>
      <.dropdown_item href={~p"/account/security"}>
        <.icon name="hero-cog-6-tooth-micro" class="size-4" /> Account
      </.dropdown_item>
      <.dropdown_divider :if={@current_scope.user.role == :admin} />
      <.dropdown_item :if={@current_scope.user.role == :admin} href={~p"/admin/claims"}>
        <.icon name="hero-shield-check-micro" class="size-4" /> Admin
      </.dropdown_item>
      <.dropdown_divider />
      <.dropdown_item href="/logout" method="delete" variant="danger">
        <.icon name="hero-arrow-right-start-on-rectangle-micro" class="size-4" /> Log out
      </.dropdown_item>
    </.dropdown>
    """
  end

  defp get_user_profile(%{id: user_id}), do: Profiles.get_profile_for_user(user_id)
  defp get_user_profile(_), do: nil
end
