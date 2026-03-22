defmodule ElixirEvents.TalksTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Profiles, Talks}

  defp create_event(_) do
    {:ok, event} =
      Events.create_event(%{
        name: "ElixirConf 2025",
        slug: "elixirconf-2025",
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2025-08-27],
        end_date: ~D[2025-08-29],
        timezone: "America/Chicago"
      })

    %{event: event}
  end

  defp create_profile(_) do
    {:ok, profile} = Profiles.create_profile(%{name: "Jose Valim", handle: "josevalim"})
    %{profile: profile}
  end

  describe "create_talk/1" do
    setup [:create_event]

    test "creates a talk with valid attrs", %{event: event} do
      assert {:ok, talk} =
               Talks.create_talk(%{
                 event_id: event.id,
                 title: "Opening Keynote",
                 slug: "opening-keynote",
                 kind: :keynote
               })

      assert talk.title == "Opening Keynote"
      assert talk.kind == :keynote
    end

    test "requires event_id, title, slug, kind" do
      assert {:error, changeset} = Talks.create_talk(%{})
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).slug
      assert "can't be blank" in errors_on(changeset).kind
      assert "can't be blank" in errors_on(changeset).event_id
    end

    test "enforces unique slug per event", %{event: event} do
      attrs = %{event_id: event.id, title: "Talk", slug: "my-talk", kind: :talk}
      {:ok, _} = Talks.create_talk(attrs)
      assert {:error, changeset} = Talks.create_talk(attrs)
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "create_recording/1" do
    setup [:create_event]

    test "creates a recording for a talk", %{event: event} do
      {:ok, talk} =
        Talks.create_talk(%{
          event_id: event.id,
          title: "Keynote",
          slug: "keynote",
          kind: :keynote
        })

      assert {:ok, rec} =
               Talks.create_recording(%{
                 talk_id: talk.id,
                 provider: :youtube,
                 external_id: "abc123",
                 url: "https://youtube.com/watch?v=abc123"
               })

      assert rec.provider == :youtube
    end
  end

  describe "create_talk_speaker/1" do
    setup [:create_event, :create_profile]

    test "links a profile to a talk", %{event: event, profile: profile} do
      {:ok, talk} =
        Talks.create_talk(%{
          event_id: event.id,
          title: "Keynote",
          slug: "keynote",
          kind: :keynote
        })

      assert {:ok, ts} =
               Talks.create_talk_speaker(%{
                 talk_id: talk.id,
                 profile_id: profile.id,
                 role: :speaker
               })

      assert ts.role == :speaker
    end
  end

  describe "create_talk_link/1" do
    setup [:create_event]

    test "creates a link for a talk", %{event: event} do
      {:ok, talk} =
        Talks.create_talk(%{
          event_id: event.id,
          title: "Keynote",
          slug: "keynote",
          kind: :keynote
        })

      assert {:ok, link} =
               Talks.create_talk_link(%{
                 talk_id: talk.id,
                 kind: :slides,
                 url: "https://speakerdeck.com/slides"
               })

      assert link.kind == :slides
    end
  end

  describe "list_talks/1" do
    setup [:create_event]

    test "returns all talks", %{event: event} do
      {:ok, _} =
        Talks.create_talk(%{event_id: event.id, title: "Talk 1", slug: "talk-1", kind: :talk})

      assert [%{title: "Talk 1"}] = Talks.list_talks()
    end

    test "filters by published (has recordings)", %{event: event} do
      {:ok, talk} =
        Talks.create_talk(%{event_id: event.id, title: "T", slug: "t-pub", kind: :talk})

      {:ok, _no_rec} =
        Talks.create_talk(%{event_id: event.id, title: "T2", slug: "t-norec", kind: :talk})

      Talks.create_recording(%{
        talk_id: talk.id,
        provider: :youtube,
        external_id: "x",
        url: "https://youtube.com/x"
      })

      published = Talks.list_talks(filter: "published")
      assert [%{id: id}] = published
      assert id == talk.id
    end

    test "filters by scheduled (no recordings)", %{event: event} do
      {:ok, talk} =
        Talks.create_talk(%{event_id: event.id, title: "T", slug: "t-sched", kind: :talk})

      {:ok, with_rec} =
        Talks.create_talk(%{event_id: event.id, title: "T2", slug: "t-rec", kind: :talk})

      Talks.create_recording(%{
        talk_id: with_rec.id,
        provider: :youtube,
        external_id: "y",
        url: "https://youtube.com/y"
      })

      scheduled = Talks.list_talks(filter: "scheduled")
      assert [%{id: id}] = scheduled
      assert id == talk.id
    end

    test "sorts by title", %{event: event} do
      {:ok, _} = Talks.create_talk(%{event_id: event.id, title: "Zebra", slug: "z", kind: :talk})
      {:ok, _} = Talks.create_talk(%{event_id: event.id, title: "Alpha", slug: "a", kind: :talk})

      [first | _] = Talks.list_talks(sort: "title")
      assert first.title == "Alpha"
    end
  end

  describe "paginate_talks/1" do
    setup [:create_event]

    test "returns paginated results", %{event: event} do
      {:ok, _} = Talks.create_talk(%{event_id: event.id, title: "T", slug: "pag", kind: :talk})
      page = Talks.paginate_talks(per_page: 1)
      assert [%{title: "T"}] = page.entries
      assert page.total_count == 1
    end
  end

  describe "list_talks_for_profile/1" do
    setup [:create_event, :create_profile]

    test "returns talks for a profile", %{event: event, profile: profile} do
      {:ok, talk} =
        Talks.create_talk(%{event_id: event.id, title: "T", slug: "prof-t", kind: :talk})

      Talks.create_talk_speaker(%{talk_id: talk.id, profile_id: profile.id, role: :speaker})

      assert [%{title: "T"}] = Talks.list_talks_for_profile(profile.id)
    end
  end

  describe "list_talks_for_event/1" do
    setup [:create_event]

    test "returns talks for an event", %{event: event} do
      {:ok, _} = Talks.create_talk(%{event_id: event.id, title: "T", slug: "evt-t", kind: :talk})
      assert [%{title: "T"}] = Talks.list_talks_for_event(event.id)
    end
  end

  describe "count_talks/0" do
    setup [:create_event]

    test "returns the number of talks", %{event: event} do
      assert Talks.count_talks() == 0
      {:ok, _} = Talks.create_talk(%{event_id: event.id, title: "T", slug: "cnt", kind: :talk})
      assert Talks.count_talks() == 1
    end
  end

  describe "get_talk_by_slug/2" do
    setup [:create_event]

    test "returns the talk", %{event: event} do
      {:ok, talk} = Talks.create_talk(%{event_id: event.id, title: "T", slug: "gbs", kind: :talk})
      assert Talks.get_talk_by_slug(event.id, "gbs").id == talk.id
    end

    test "returns nil for non-existent slug", %{event: event} do
      assert Talks.get_talk_by_slug(event.id, "nope") == nil
    end
  end

  describe "get_talk_by_event_and_slug/2" do
    setup [:create_event]

    test "returns the talk by event and talk slugs", %{event: event} do
      {:ok, talk} =
        Talks.create_talk(%{event_id: event.id, title: "T", slug: "gbes", kind: :talk})

      assert Talks.get_talk_by_event_and_slug("elixirconf-2025", "gbes").id == talk.id
    end

    test "returns nil for non-existent combination" do
      assert Talks.get_talk_by_event_and_slug("nope", "nope") == nil
    end
  end

  describe "upsert_talk/1" do
    setup [:create_event]

    test "inserts a new talk", %{event: event} do
      assert {:ok, talk} =
               Talks.upsert_talk(%{
                 event_id: event.id,
                 title: "Keynote",
                 slug: "keynote",
                 kind: :keynote
               })

      assert talk.title == "Keynote"
    end

    test "updates an existing talk by event_id + slug", %{event: event} do
      {:ok, _} =
        Talks.upsert_talk(%{
          event_id: event.id,
          title: "Keynote",
          slug: "keynote",
          kind: :keynote
        })

      {:ok, updated} =
        Talks.upsert_talk(%{
          event_id: event.id,
          title: "Opening Keynote",
          slug: "keynote",
          kind: :keynote
        })

      assert updated.title == "Opening Keynote"
    end
  end

  describe "replace_recordings/2" do
    setup [:create_event]

    test "replaces all recordings for a talk", %{event: event} do
      {:ok, talk} = Talks.create_talk(%{event_id: event.id, title: "T", slug: "t", kind: :talk})
      Talks.create_recording(%{talk_id: talk.id, provider: :youtube, url: "https://old.com"})

      {:ok, recs} =
        Talks.replace_recordings(talk.id, [
          %{provider: :youtube, external_id: "abc", url: "https://youtube.com/watch?v=abc"}
        ])

      assert length(recs) == 1
      assert hd(recs).external_id == "abc"
    end
  end

  describe "replace_talk_speakers/2" do
    setup [:create_event, :create_profile]

    test "replaces all speakers for a talk", %{event: event, profile: profile} do
      {:ok, talk} = Talks.create_talk(%{event_id: event.id, title: "T", slug: "t2", kind: :talk})

      {:ok, tss} =
        Talks.replace_talk_speakers(talk.id, [
          %{profile_id: profile.id, role: :speaker, position: 1}
        ])

      assert length(tss) == 1
    end
  end

  describe "replace_talk_links/2" do
    setup [:create_event]

    test "replaces all links for a talk", %{event: event} do
      {:ok, talk} = Talks.create_talk(%{event_id: event.id, title: "T", slug: "t3", kind: :talk})

      {:ok, links} =
        Talks.replace_talk_links(talk.id, [
          %{kind: :slides, url: "https://slides.com/deck"}
        ])

      assert length(links) == 1
    end
  end
end
