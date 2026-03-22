defmodule ElixirEventsWeb.UserLive.RegistrationTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/join")

      assert html =~ "Create an account"
      assert html =~ "Sign in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/join")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/join")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces"})

      assert result =~ "Create an account"
      assert result =~ "must have the @ sign and no spaces"
    end
  end

  describe "register user" do
    test "creates account but does not log in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/join")

      email = unique_user_email()

      form =
        form(lv, "#registration_form",
          user:
            valid_user_attributes(email: email)
            |> Map.put(:password, valid_user_password())
        )

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/login")

      assert html =~
               ~r/Check your inbox at .* for a confirmation link/
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/join")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email, "password" => valid_user_password()}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Sign in link is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/join")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign in")
        |> render_click()
        |> follow_redirect(conn, ~p"/login")

      assert login_html =~ "Sign in"
    end
  end
end
