defmodule ElixirEventsWeb.Plugs.AdminAuthTest do
  use ElixirEventsWeb.ConnCase, async: true

  import ElixirEvents.AccountsFixtures

  alias ElixirEvents.Accounts.Scope
  alias ElixirEventsWeb.Plugs.AdminAuth

  describe "require_admin_user/2" do
    test "redirects non-authenticated requests to home", %{conn: conn} do
      # Simulate the browser pipeline having run but no user logged in
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> fetch_flash()
        |> assign(:current_scope, nil)

      conn = AdminAuth.require_admin_user(conn, [])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must be an admin"
    end

    test "redirects regular (non-admin) users to home", %{conn: conn} do
      user = user_fixture()
      scope = Scope.for_user(user)

      conn =
        conn
        |> log_in_user(user)
        |> fetch_flash()
        |> assign(:current_scope, scope)

      conn = AdminAuth.require_admin_user(conn, [])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must be an admin"
    end

    test "allows admin users and assigns :current_admin", %{conn: conn} do
      user = user_fixture()

      admin =
        user
        |> Ecto.Changeset.change(role: :admin)
        |> ElixirEvents.Repo.update!()

      scope = Scope.for_user(admin)

      conn =
        conn
        |> log_in_user(admin)
        |> fetch_flash()
        |> assign(:current_scope, scope)

      conn = AdminAuth.require_admin_user(conn, [])

      refute conn.halted
      assert conn.assigns.current_admin == admin
    end
  end
end
