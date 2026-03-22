defmodule ElixirEventsWeb.UserLive.Login do
  use ElixirEventsWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <div class="mb-10">
          <h1 class="font-display text-3xl font-bold text-base-content">Sign in</h1>
          <p :if={!@current_scope} class="text-base-content/55 mt-2">
            Don't have an account?
            <.link
              navigate={~p"/join"}
              class="font-semibold text-primary hover:text-primary/70"
            >
              Sign up
            </.link>
          </p>
          <p :if={@current_scope} class="text-base-content/55 mt-2">
            Please sign in again to continue.
          </p>
        </div>

        <div class="p-6 rounded-2xl bg-base-200/30 border border-base-300/50">
          <.form
            :let={f}
            for={@form}
            id="login_form"
            action={~p"/login"}
            phx-submit="submit"
            phx-trigger-action={@trigger_submit}
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
              phx-mounted={JS.focus()}
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
            />
            <.button size="lg" class="mt-2" name={@form[:remember_me].name} value="true">
              Sign in <span aria-hidden="true">&rarr;</span>
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
