defmodule ElixirEventsWeb.TopicLiveTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ElixirEvents.Topics

  describe "Index" do
    test "renders topics page", %{conn: conn} do
      {:ok, _} = Topics.create_topic(%{name: "LiveView", slug: "liveview"})
      {:ok, _lv, html} = live(conn, ~p"/topics")
      assert html =~ "LiveView"
    end
  end

  describe "Show" do
    test "renders topic detail page", %{conn: conn} do
      {:ok, _} = Topics.create_topic(%{name: "LiveView", slug: "liveview"})
      {:ok, _lv, html} = live(conn, ~p"/topics/liveview")
      assert html =~ "LiveView"
    end

    test "redirects for non-existent topic", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/topics"}}} =
               live(conn, ~p"/topics/nonexistent")
    end
  end
end
