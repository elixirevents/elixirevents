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

  describe "handle conflict detection" do
    alias ElixirEvents.Profiles

    test "shows unclaimed conflict notice when handle matches unclaimed speaker", %{conn: conn} do
      {:ok, _} = Profiles.create_profile(%{name: "Hugo Barauna", handle: "hugobarauna"})
      {:ok, lv, _html} = live(conn, ~p"/join")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"handle" => "hugobarauna"})

      assert result =~ "Hugo Barauna"
      assert result =~ "Claim this speaker profile"
    end

    test "shows claimed conflict notice when handle matches claimed profile", %{conn: conn} do
      user = user_fixture(%{handle: "takenhandle"})
      profile = Profiles.get_profile_for_user(user.id)

      {:ok, lv, _html} = live(conn, ~p"/join")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"handle" => profile.handle})

      assert result =~ "belongs to someone else"
    end

    test "shows no conflict notice for available handle", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/join")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"handle" => "available"})

      refute result =~ "Claim"
      refute result =~ "belongs to someone else"
    end

    test "suggests alternative handle when conflict detected", %{conn: conn} do
      {:ok, _} = Profiles.create_profile(%{name: "Hugo Barauna", handle: "hugobarauna"})
      {:ok, lv, _html} = live(conn, ~p"/join")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"handle" => "hugobarauna"})

      assert result =~ "hugobarauna1"
    end

    test "re-entering conflicting handle shows conflict notice again", %{conn: conn} do
      {:ok, _} = Profiles.create_profile(%{name: "Hugo Barauna", handle: "hugobarauna"})
      {:ok, lv, _html} = live(conn, ~p"/join")

      lv |> element("#registration_form") |> render_change(user: %{"handle" => "hugobarauna"})
      lv |> element("#registration_form") |> render_change(user: %{"handle" => "somethingelse"})

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"handle" => "hugobarauna"})

      assert result =~ "Hugo Barauna"
      assert result =~ "Claim this speaker profile"
    end

    test "conflict notice disappears when handle changes to non-conflicting", %{conn: conn} do
      {:ok, _} = Profiles.create_profile(%{name: "Hugo Barauna", handle: "hugobarauna"})
      {:ok, lv, _html} = live(conn, ~p"/join")

      lv |> element("#registration_form") |> render_change(user: %{"handle" => "hugobarauna"})

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"handle" => "somethingelse"})

      refute result =~ "Claim"
      refute result =~ "Hugo Barauna"
    end
  end

  describe "register with claim" do
    alias ElixirEvents.{Claims, Profiles}

    test "submit with claim opted in creates user and pending claim", %{conn: conn} do
      {:ok, speaker} = Profiles.create_profile(%{name: "Hugo Barauna", handle: "hugobarauna"})
      {:ok, lv, _html} = live(conn, ~p"/join")

      # Trigger conflict detection first
      lv
      |> element("#registration_form")
      |> render_change(user: %{"handle" => "hugobarauna"})

      # Submit with the suggested handle and claim opted in
      attrs =
        valid_user_attributes(handle: "hugobarauna1")
        |> Map.put(:password, valid_user_password())

      {:ok, _lv, html} =
        lv
        |> form("#registration_form",
          user: attrs,
          claim_profile: "true",
          claim_user_notes: "DM me on Twitter"
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      assert html =~ "Claim submitted for"
      assert html =~ "Hugo Barauna"

      # Verify claim was created
      user = ElixirEvents.Accounts.get_user_by_email(attrs.email)
      claim = Claims.get_user_claim(user, "profile", speaker.id)
      assert claim != nil
      assert claim.status == :pending
      assert claim.user_notes == "DM me on Twitter"
    end

    test "submit without claim creates user normally", %{conn: conn} do
      {:ok, _} = Profiles.create_profile(%{name: "Hugo Barauna", handle: "hugobarauna"})
      {:ok, lv, _html} = live(conn, ~p"/join")

      attrs =
        valid_user_attributes(handle: "somethingelse")
        |> Map.put(:password, valid_user_password())

      {:ok, _lv, html} =
        lv
        |> form("#registration_form", user: attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      assert html =~ ~r/Check your inbox at .* for a confirmation link/
      refute html =~ "claim"
    end

    test "submit with conflicting handle directly shows error", %{conn: conn} do
      {:ok, _} = Profiles.create_profile(%{name: "Hugo Barauna", handle: "hugobarauna"})
      {:ok, lv, _html} = live(conn, ~p"/join")

      attrs =
        valid_user_attributes(handle: "hugobarauna")
        |> Map.put(:password, valid_user_password())

      result =
        lv
        |> form("#registration_form", user: attrs)
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
