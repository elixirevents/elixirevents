defmodule ElixirEventsWeb.Plugs.AdminAuth do
  @moduledoc false

  use ElixirEventsWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  @doc """
  Plug that requires the current user to have the :admin role.

  Must be used after :fetch_current_scope_for_user has run (i.e., after the
  :browser pipeline). Assigns :current_admin to the conn on success.
  """
  def require_admin_user(conn, _opts) do
    case conn.assigns[:current_scope] do
      %{user: %{role: :admin} = admin} ->
        assign(conn, :current_admin, admin)

      _ ->
        conn
        |> put_flash(:error, "You must be an admin to access this page.")
        |> redirect(to: ~p"/")
        |> halt()
    end
  end

  @doc """
  LiveView on_mount hook that ensures the current user is an admin.

  Assigns :current_admin to the socket on success. Redirects to "/" with an
  error flash on failure.
  """
  def on_mount(:ensure_admin_authenticated, _params, session, socket) do
    socket =
      Phoenix.Component.assign_new(socket, :current_admin, fn ->
        {user, _} =
          if user_token = session["user_token"] do
            ElixirEvents.Accounts.get_user_by_session_token(user_token)
          end || {nil, nil}

        if user && user.role == :admin, do: user
      end)

    if socket.assigns.current_admin do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must be an admin to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/")

      {:halt, socket}
    end
  end

  # Assigns the current request path for admin sidebar navigation.
  def on_mount(:assign_admin_path, _params, _session, socket) do
    {:cont,
     Phoenix.LiveView.attach_hook(socket, :assign_admin_path, :handle_params, fn
       _params, uri, socket ->
         {:cont, Phoenix.Component.assign(socket, :current_path, URI.parse(uri).path)}
     end)}
  end
end
