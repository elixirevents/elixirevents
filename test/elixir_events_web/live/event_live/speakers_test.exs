defmodule ElixirEventsWeb.EventLive.SpeakersTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.DataFixtures

  alias ElixirEvents.Talks

  describe "Speakers sub-page" do
    test "renders speakers grouped by keynote vs regular", %{conn: conn} do
      series = event_series_fixture()
      event = event_fixture(series, %{name: "Speaker Conf", slug: "speaker-conf"})
      keynote_speaker = profile_fixture(%{name: "Jane Keynote", handle: "janekeynote"})
      regular_speaker = profile_fixture(%{name: "Bob Regular", handle: "bobregular"})

      keynote = talk_fixture(event, %{title: "Opening", slug: "opening", kind: :keynote})
      talk = talk_fixture(event, %{title: "My Talk", slug: "my-talk", kind: :talk})

      Talks.replace_talk_speakers(keynote.id, [
        %{profile_id: keynote_speaker.id, role: :speaker, position: 1}
      ])

      Talks.replace_talk_speakers(talk.id, [
        %{profile_id: regular_speaker.id, role: :speaker, position: 1}
      ])

      {:ok, _lv, html} = live(conn, ~p"/events/speaker-conf/speakers")
      assert html =~ "Jane Keynote"
      assert html =~ "Bob Regular"
      assert html =~ "Keynote Speakers"
    end

    test "shows empty state when no speakers", %{conn: conn} do
      series = event_series_fixture()
      _event = event_fixture(series, %{name: "Empty Conf", slug: "empty-conf"})

      {:ok, _lv, html} = live(conn, ~p"/events/empty-conf/speakers")
      assert html =~ "No speakers listed"
    end

    test "redirects when no event found", %{conn: conn} do
      assert {:error, {:live_redirect, _}} = live(conn, ~p"/events/nope/speakers")
    end
  end
end
