defmodule ElixirEventsWeb.UserSessionController do
  use ElixirEventsWeb, :controller

  alias ElixirEvents.Accounts
  alias ElixirEventsWeb.UserAuth

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      %{confirmed_at: nil} ->
        conn
        |> put_flash(
          :error,
          "Please confirm your email before signing in. Check your inbox for the confirmation link."
        )
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/login")

      user when not is_nil(user) ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      nil ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/login")
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)
    {:ok, {_user, expired_tokens}} = Accounts.update_user_password(user, user_params)

    # disconnect all existing LiveViews with old sessions
    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:user_return_to, ~p"/account/security")
    |> create(params, "Password updated.")
  end

  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email confirmed — you can now sign in.")
        |> redirect(to: ~p"/login")

      :error ->
        conn
        |> put_flash(:error, "That confirmation link is invalid or has expired.")
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You've been signed out.")
    |> UserAuth.log_out_user()
  end
end
