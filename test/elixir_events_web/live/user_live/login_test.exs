defmodule ElixirEventsWeb.UserLive.LoginTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.AccountsFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      assert html =~ "Sign in"
      assert html =~ "Sign up"
    end
  end

  describe "user login - password" do
    test "redirects if user logs in with valid credentials", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login_form",
          user: %{email: user.email, password: valid_user_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login_form", user: %{email: "test@email.com", password: "123456"})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password."
      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Sign up link is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/login")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/join")

      assert login_html =~ "Create an account"
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "shows login page with reauthenticate message", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      assert html =~ "Please sign in again to continue."
      refute html =~ "Sign up"

      assert html =~
               ~s(<input type="email" name="user[email]" id="login_form_email" value="#{user.email}")
    end
  end
end
