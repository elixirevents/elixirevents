defmodule ElixirEventsWeb.Admin.ClaimLiveTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.AccountsFixtures

  alias ElixirEvents.{Claims, Profiles}

  defp create_admin(_) do
    admin =
      user_fixture()
      |> Ecto.Changeset.change(role: :admin)
      |> ElixirEvents.Repo.update!()

    %{admin: admin}
  end

  defp log_in_admin(%{conn: conn, admin: admin}) do
    %{conn: log_in_user(conn, admin)}
  end

  defp create_claim(_) do
    user = user_fixture()

    {:ok, profile} =
      Profiles.create_profile(%{
        name: "Speaker #{System.unique_integer([:positive])}",
        handle: "speaker#{System.unique_integer([:positive])}"
      })

    {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
    %{claim: claim, claimer: user, profile: profile}
  end

  describe "Index" do
    setup [:create_admin, :log_in_admin, :create_claim]

    test "renders claims list", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/claims")
      assert html =~ "Claims"
    end

    test "filters by status", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/claims?status=pending")
      assert html =~ "Claims"
    end
  end

  describe "Show" do
    setup [:create_admin, :log_in_admin, :create_claim]

    test "renders claim detail", %{conn: conn, claim: claim} do
      {:ok, _lv, html} = live(conn, ~p"/admin/claims/#{claim.id}")
      assert html =~ "Claim"
    end

    test "approves a claim", %{conn: conn, claim: claim} do
      {:ok, lv, _html} = live(conn, ~p"/admin/claims/#{claim.id}")
      html = lv |> element("[phx-click=approve]") |> render_click()
      assert html =~ "approved" or follow_redirect(lv, conn)
    end

    test "rejects a claim with notes", %{conn: conn, claim: claim} do
      {:ok, lv, _html} = live(conn, ~p"/admin/claims/#{claim.id}")

      html =
        lv
        |> form("[phx-submit=reject]", admin_notes: "Insufficient evidence")
        |> render_submit()

      assert html =~ "rejected" or follow_redirect(lv, conn)
    end
  end

  describe "Admin auth required" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/claims")
    end

    test "redirects unauthenticated users", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/claims")
    end
  end
end
