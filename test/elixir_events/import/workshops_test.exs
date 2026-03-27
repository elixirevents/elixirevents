defmodule ElixirEvents.Import.WorkshopsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Profiles, Topics, Venues, Workshops}
  alias ElixirEvents.Import

  setup do
    {:ok, event} =
      Events.create_event(%{
        name: "Conf Workshops Import",
        slug: "conf-workshops-import",
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2026-05-18],
        end_date: ~D[2026-05-20],
        timezone: "Europe/Stockholm"
      })

    {:ok, _} = Profiles.create_profile(%{name: "Robert Virding WS", handle: "robertvirdingws"})
    {:ok, _} = Topics.create_topic(%{name: "Erlang WS", slug: "erlang-ws"})
    {:ok, _} = Venues.create_venue(%{name: "IOFFICE Test", slug: "ioffice-test"})

    %{event: event}
  end

  @tag :tmp_dir
  test "imports workshops with trainers, topics, and venue", %{event: event, tmp_dir: tmp_dir} do
    yaml = """
    - title: "Secure Coding in BEAM"
      slug: "secure-coding-in-beam"
      start_date: "2026-05-22"
      end_date: "2026-05-22"
      experience_level: "Intermediate"
      venue_slug: ioffice-test
      description: "Learn about secure coding."
      trainers:
        - robertvirdingws
      topics:
        - erlang-ws
      agenda:
        - day: 1
          title: "Day One"
          start_time: "09:00"
          end_time: "17:00"
          items:
            - "Secure coding recommendations"
            - "Reducing vulnerabilities"
    """

    File.write!(Path.join(tmp_dir, "workshops.yml"), yaml)

    assert :ok = Import.Workshops.run(tmp_dir, event)

    workshops =
      Workshops.list_workshops_for_event(event.id, preload: [workshop_trainers: :profile])

    assert [%{title: "Secure Coding in BEAM"} = workshop] = workshops
    assert workshop.experience_level == "Intermediate"
    assert workshop.venue_id != nil
    assert [%{profile: %{handle: "robertvirdingws"}}] = workshop.workshop_trainers
    assert [%{day_number: 1, title: "Day One"}] = workshop.agenda
  end

  @tag :tmp_dir
  test "skips when workshops.yml does not exist", %{event: event, tmp_dir: tmp_dir} do
    assert {:ok, :skipped} = Import.Workshops.run(tmp_dir, event)
  end

  @tag :tmp_dir
  test "deletes orphaned workshops", %{event: event, tmp_dir: tmp_dir} do
    {:ok, _} =
      Workshops.upsert_workshop(%{
        event_id: event.id,
        title: "Old Workshop",
        slug: "old-workshop",
        start_date: ~D[2026-05-22],
        end_date: ~D[2026-05-22]
      })

    yaml = """
    - title: "New Workshop"
      slug: "new-workshop"
      start_date: "2026-05-22"
      end_date: "2026-05-22"
    """

    File.write!(Path.join(tmp_dir, "workshops.yml"), yaml)

    assert :ok = Import.Workshops.run(tmp_dir, event)

    workshops = Workshops.list_workshops_for_event(event.id)
    assert [%{slug: "new-workshop"}] = workshops
  end
end
