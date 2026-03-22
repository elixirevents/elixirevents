defmodule ElixirEventsWeb.UserLive.Registration do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Accounts
  alias ElixirEvents.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <div class="mb-10">
          <h1 class="font-display text-3xl font-bold text-base-content">Create an account</h1>
          <p class="text-base-content/55 mt-2">
            Already have an account?
            <.link
              navigate={~p"/login"}
              class="font-semibold text-primary hover:text-primary/70"
            >
              Sign in
            </.link>
          </p>
        </div>

        <div class="p-6 rounded-2xl bg-base-200/30 border border-base-300/50">
          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
            <.input field={@form[:first_name]} type="text" label="First name" required />
            <.input field={@form[:last_name]} type="text" label="Last name" required />
            <.input
              field={@form[:handle]}
              type="text"
              label="Handle"
              required
              placeholder="e.g. josevalim"
            />
            <.input field={@form[:email]} type="email" label="Email" autocomplete="username" required />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="new-password"
              required
            />
            <.button size="lg" class="mt-2" phx-disable-with="Creating account...">
              Create an account
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: ElixirEventsWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_confirmation_instructions(
            user,
            &url(~p"/confirm/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(:info, "Check your inbox at #{user.email} for a confirmation link.")
         |> push_navigate(to: ~p"/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
