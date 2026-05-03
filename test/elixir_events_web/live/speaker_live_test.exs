defmodule ElixirEventsWeb.SpeakerLiveTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.DataFixtures

  alias ElixirEvents.{Profiles, Talks}

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

    test "renders sort toolbar", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/speakers")
      assert html =~ "A–Z"
      assert html =~ "Most talks"
    end

    test "sorts by talk count when sort=talks", %{conn: conn} do
      series = event_series_fixture()
      event = event_fixture(series)

      prolific = profile_fixture(%{name: "Prolific Speaker"})
      occasional = profile_fixture(%{name: "Aaron Occasional"})

      for _ <- 1..3 do
        talk = talk_fixture(event)

        {:ok, _} =
          Talks.create_talk_speaker(%{
            talk_id: talk.id,
            profile_id: prolific.id,
            role: :speaker
          })
      end

      one_talk = talk_fixture(event)

      {:ok, _} =
        Talks.create_talk_speaker(%{
          talk_id: one_talk.id,
          profile_id: occasional.id,
          role: :speaker
        })

      {:ok, _lv, html} = live(conn, ~p"/speakers?sort=talks")

      prolific_pos = :binary.match(html, "Prolific Speaker") |> elem(0)
      occasional_pos = :binary.match(html, "Aaron Occasional") |> elem(0)
      assert prolific_pos < occasional_pos

      {:ok, _lv, html} = live(conn, ~p"/speakers")
      prolific_pos = :binary.match(html, "Prolific Speaker") |> elem(0)
      occasional_pos = :binary.match(html, "Aaron Occasional") |> elem(0)
      assert occasional_pos < prolific_pos
    end
  end
end
