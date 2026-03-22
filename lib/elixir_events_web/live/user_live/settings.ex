defmodule ElixirEventsWeb.UserLive.Settings do
  use ElixirEventsWeb, :live_view

  on_mount {ElixirEventsWeb.UserAuth, :require_sudo_mode}

  alias ElixirEvents.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-lg">
      <div class="mb-10">
        <h1 class="font-display text-3xl font-bold text-base-content">Account</h1>
        <p class="text-base-content/55 mt-2">Email and security settings</p>
      </div>

      <div class="p-6 rounded-2xl bg-base-200/30 border border-base-300/50 mb-8">
        <h2 class="font-display text-lg font-bold text-base-content mb-4">Email</h2>
        <.form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input
            field={@email_form[:email]}
            type="email"
            label="Email address"
            autocomplete="username"
            required
          />
          <.button class="mt-2" phx-disable-with="Changing...">
            Change email
          </.button>
        </.form>
      </div>

      <div class="p-6 rounded-2xl bg-base-200/30 border border-base-300/50">
        <h2 class="font-display text-lg font-bold text-base-content mb-4">Password</h2>
        <.form
          for={@password_form}
          id="password_form"
          action={~p"/account/security/update-password"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            autocomplete="username"
            value={@current_email}
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            required
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
          />
          <.button class="mt-2" phx-disable-with="Saving...">
            Save password
          </.button>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email updated.")

        {:error, _} ->
          put_flash(socket, :error, "That link is invalid or has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/account/security")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/account/security/confirm-email/#{&1}")
        )

        info = "Check your new inbox for a confirmation link."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
