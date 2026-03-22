defmodule ElixirEventsWeb.SpeakerLiveTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ElixirEvents.Profiles

  describe "Index" do
    test "renders speakers page", %{conn: conn} do
      {:ok, _} =
        Profiles.create_profile(%{name: "Jose Valim", handle: "josevalim", is_speaker: true})

      {:ok, _lv, html} = live(conn, ~p"/speakers")
      assert html =~ "Jose Valim"
    end

    test "handles pagination param", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/speakers?page=1")
      assert html =~ "Speakers"
    end
  end
end
