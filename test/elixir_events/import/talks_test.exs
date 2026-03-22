defmodule ElixirEvents.Import.TalksTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Profiles, Talks, Topics}
  alias ElixirEvents.Import

  setup do
    {:ok, event} =
      Events.create_event(%{
        name: "Conf Talks Import",
        slug: "conf-talks-import",
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2025-01-01],
        end_date: ~D[2025-01-02],
        timezone: "UTC"
      })

    {:ok, _} = Profiles.create_profile(%{name: "Jose Valim Import", handle: "josevalimimport"})
    {:ok, _} = Topics.create_topic(%{name: "Elixir Import", slug: "elixir-import"})

    %{event: event}
  end

  @tag :tmp_dir
  test "imports talks with speakers, topics, recordings, and links",
       %{event: event, tmp_dir: tmp_dir} do
    yaml = """
    - title: "Keynote"
      slug: "keynote"
      kind: keynote
      speakers:
        - josevalimimport
      topics:
        - elixir-import
      recordings:
        - provider: youtube
          external_id: "abc123"
          url: "https://youtube.com/watch?v=abc123"
      links:
        - kind: slides
          url: "https://slides.com/deck"
    """

    File.write!(Path.join(tmp_dir, "talks.yml"), yaml)

    assert :ok = Import.Talks.run(tmp_dir, event)

    talks = Talks.list_talks_for_event(event.id)
    assert length(talks) == 1
  end

  @tag :tmp_dir
  test "skips missing speaker slugs gracefully", %{event: event, tmp_dir: tmp_dir} do
    yaml = """
    - title: "Talk"
      slug: "talk"
      kind: talk
      speakers:
        - nonexistent-speaker
    """

    File.write!(Path.join(tmp_dir, "talks.yml"), yaml)

    assert :ok = Import.Talks.run(tmp_dir, event)
    assert length(Talks.list_talks_for_event(event.id)) == 1
  end
end
