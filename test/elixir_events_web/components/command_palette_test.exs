defmodule ElixirEventsWeb.CommandPaletteTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "command palette in layout" do
    test "renders command palette overlay in app layout", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")
      html = render(view)

      assert html =~ "command-palette"
      assert html =~ "data-palette-overlay"
      assert html =~ "data-palette-input"
    end
  end
end
