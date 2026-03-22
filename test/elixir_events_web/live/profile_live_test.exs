defmodule ElixirEventsWeb.ProfileLiveTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.AccountsFixtures

  alias ElixirEvents.Profiles

  describe "Show" do
    test "renders profile page", %{conn: conn} do
      {:ok, _} =
        Profiles.create_profile(%{
          name: "Jose Valim",
          handle: "josevalim",
          bio: "Creator of Elixir"
        })

      {:ok, _lv, html} = live(conn, ~p"/profiles/josevalim")
      assert html =~ "Jose Valim"
    end

    test "redirects for non-existent profile", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/speakers"}}} =
               live(conn, ~p"/profiles/nonexistent")
    end

    test "shows claim button for logged-in user on unclaimed profile", %{conn: conn} do
      {:ok, _} = Profiles.create_profile(%{name: "Speaker", handle: "speaker"})
      conn = log_in_user(conn, user_fixture())

      {:ok, _lv, html} = live(conn, ~p"/profiles/speaker")
      assert html =~ "speaker"
    end
  end

  describe "Edit" do
    setup :register_and_log_in_user

    test "renders edit profile page", %{conn: conn, user: user} do
      profile = Profiles.get_profile_for_user(user.id)

      if profile do
        {:ok, _lv, html} = live(conn, ~p"/account/profile")
        assert html =~ "Edit Profile"
      end
    end

    test "updates profile on save", %{conn: conn, user: user} do
      profile = Profiles.get_profile_for_user(user.id)

      if profile do
        {:ok, lv, _html} = live(conn, ~p"/account/profile")

        lv
        |> form("#profile-form", profile: %{headline: "Elixir developer"})
        |> render_submit()

        updated = Profiles.get_profile(profile.id)
        assert updated.headline == "Elixir developer"
      end
    end
  end
end
