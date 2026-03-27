defmodule ElixirEvents.EventsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Events

  @valid_series_attrs %{
    name: "ElixirConf",
    slug: "elixirconf",
    kind: :conference,
    frequency: :yearly,
    language: "en"
  }

  @valid_event_attrs %{
    name: "ElixirConf US 2025",
    slug: "elixirconf-us-2025",
    kind: :conference,
    status: :confirmed,
    format: :in_person,
    start_date: ~D[2025-08-27],
    end_date: ~D[2025-08-29],
    timezone: "America/Chicago",
    language: "en",
    location: "Grapevine, TX, USA"
  }

  describe "create_event_series/1" do
    test "creates a series with valid attrs" do
      assert {:ok, series} = Events.create_event_series(@valid_series_attrs)
      assert series.name == "ElixirConf"
      assert series.kind == :conference
    end

    test "requires name, slug, and kind" do
      assert {:error, changeset} = Events.create_event_series(%{})
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).slug
      assert "can't be blank" in errors_on(changeset).kind
    end

    test "supports social_links embed" do
      attrs =
        Map.put(@valid_series_attrs, :social_links, [
          %{platform: :twitter, url: "https://twitter.com/elixirconf"}
        ])

      assert {:ok, series} = Events.create_event_series(attrs)
      assert [%{platform: :twitter}] = series.social_links
    end
  end

  describe "create_event/1" do
    test "creates an event with valid attrs" do
      assert {:ok, event} = Events.create_event(@valid_event_attrs)
      assert event.name == "ElixirConf US 2025"
      assert event.kind == :conference
      assert event.status == :confirmed
      assert event.format == :in_person
    end

    test "creates an event belonging to a series" do
      {:ok, series} = Events.create_event_series(@valid_series_attrs)
      attrs = Map.put(@valid_event_attrs, :event_series_id, series.id)
      assert {:ok, event} = Events.create_event(attrs)
      assert event.event_series_id == series.id
    end

    test "requires mandatory fields" do
      assert {:error, changeset} = Events.create_event(%{})
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).slug
      assert "can't be blank" in errors_on(changeset).kind
      assert "can't be blank" in errors_on(changeset).status
      assert "can't be blank" in errors_on(changeset).format
      assert "can't be blank" in errors_on(changeset).start_date
      assert "can't be blank" in errors_on(changeset).end_date
      assert "can't be blank" in errors_on(changeset).timezone
    end

    test "enforces unique slug" do
      {:ok, _} = Events.create_event(@valid_event_attrs)
      assert {:error, changeset} = Events.create_event(@valid_event_attrs)
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "create_event_link/1" do
    test "creates a link for an event" do
      {:ok, event} = Events.create_event(@valid_event_attrs)

      assert {:ok, link} =
               Events.create_event_link(%{
                 event_id: event.id,
                 kind: :code_of_conduct,
                 url: "https://example.com/coc"
               })

      assert link.kind == :code_of_conduct
    end

    test "requires event_id, kind, and url" do
      assert {:error, changeset} = Events.create_event_link(%{})
      assert "can't be blank" in errors_on(changeset).event_id
      assert "can't be blank" in errors_on(changeset).kind
      assert "can't be blank" in errors_on(changeset).url
    end
  end

  describe "create_event_role/1" do
    test "creates a role for an event" do
      {:ok, event} = Events.create_event(@valid_event_attrs)

      assert {:ok, role} =
               Events.create_event_role(%{
                 event_id: event.id,
                 name: "John Doe",
                 role: :organizer
               })

      assert role.role == :organizer
    end

    test "requires event_id, name, and role" do
      assert {:error, changeset} = Events.create_event_role(%{})
      assert "can't be blank" in errors_on(changeset).event_id
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).role
    end
  end

  describe "list_events/0" do
    test "returns all events" do
      {:ok, event} = Events.create_event(@valid_event_attrs)
      assert [found] = Events.list_events()
      assert found.id == event.id
    end

    test "returns events of all kinds including meetups" do
      {:ok, _conference} = Events.create_event(@valid_event_attrs)

      {:ok, _meetup} =
        Events.create_event(%{
          @valid_event_attrs
          | name: "Braga BEAM #8",
            slug: "bbug-8",
            kind: :meetup
        })

      {:ok, _retreat} =
        Events.create_event(%{
          @valid_event_attrs
          | name: "EMPEX Retreat",
            slug: "empex-retreat",
            kind: :retreat
        })

      events = Events.list_events()
      kinds = Enum.map(events, & &1.kind)
      assert :conference in kinds
      assert :meetup in kinds
      assert :retreat in kinds
    end

    test "excludes events from unlisted series" do
      {:ok, listed_series} =
        Events.create_event_series(%{@valid_series_attrs | slug: "listed-series"})

      {:ok, unlisted_series} =
        Events.create_event_series(%{
          @valid_series_attrs
          | slug: "unlisted-series",
            name: "External Conf"
        })

      Events.upsert_event_series(%{
        name: "External Conf",
        slug: "unlisted-series",
        kind: :conference,
        listed: false
      })

      {:ok, _listed_event} =
        Events.create_event(
          %{
            @valid_event_attrs
            | slug: "listed-event"
          }
          |> Map.put(:event_series_id, listed_series.id)
        )

      {:ok, _unlisted_event} =
        Events.create_event(
          %{
            @valid_event_attrs
            | slug: "unlisted-event"
          }
          |> Map.put(:event_series_id, unlisted_series.id)
        )

      events = Events.list_events()
      slugs = Enum.map(events, & &1.slug)
      assert "listed-event" in slugs
      refute "unlisted-event" in slugs
    end

    test "includes events without a series" do
      {:ok, _event} = Events.create_event(@valid_event_attrs)
      assert [%{slug: "elixirconf-us-2025"}] = Events.list_events()
    end

    test "returns events ordered by year descending, then date ascending within each year" do
      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "early-2025",
            start_date: ~D[2025-03-01],
            end_date: ~D[2025-03-02]
        })

      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "late-2025",
            name: "Late 2025",
            start_date: ~D[2025-11-01],
            end_date: ~D[2025-11-02]
        })

      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "mid-2025",
            name: "Mid 2025",
            kind: :meetup,
            start_date: ~D[2025-06-15],
            end_date: ~D[2025-06-15]
        })

      slugs = Events.list_events() |> Enum.map(& &1.slug)
      assert slugs == ["early-2025", "mid-2025", "late-2025"]
    end

    test "meetups are interleaved chronologically within year, not grouped separately" do
      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "conf-oct",
            start_date: ~D[2026-10-01],
            end_date: ~D[2026-10-02]
        })

      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "meetup-mar",
            name: "BBUG #8",
            kind: :meetup,
            start_date: ~D[2026-03-26],
            end_date: ~D[2026-03-26]
        })

      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "conf-may",
            name: "Code BEAM Lite",
            start_date: ~D[2026-05-18],
            end_date: ~D[2026-05-19]
        })

      slugs = Events.list_events() |> Enum.map(& &1.slug)
      assert slugs == ["meetup-mar", "conf-may", "conf-oct"]
    end

    test "events from different years are grouped by year descending" do
      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "event-2026",
            start_date: ~D[2026-03-01],
            end_date: ~D[2026-03-02]
        })

      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "event-2025",
            name: "Conf 2025",
            start_date: ~D[2025-11-01],
            end_date: ~D[2025-11-02]
        })

      slugs = Events.list_events() |> Enum.map(& &1.slug)
      assert slugs == ["event-2026", "event-2025"]
    end
  end

  describe "get_event_by_slug/1" do
    test "returns the event" do
      {:ok, event} = Events.create_event(@valid_event_attrs)
      assert Events.get_event_by_slug("elixirconf-us-2025").id == event.id
    end
  end

  describe "list_event_series/0" do
    test "returns all listed series" do
      {:ok, series} = Events.create_event_series(@valid_series_attrs)
      assert [found] = Events.list_event_series()
      assert found.id == series.id
    end

    test "excludes unlisted series" do
      {:ok, _listed} = Events.create_event_series(@valid_series_attrs)

      {:ok, _unlisted} =
        Events.create_event_series(%{
          name: "YOW!",
          slug: "yow",
          kind: :conference,
          listed: false
        })

      series = Events.list_event_series()
      slugs = Enum.map(series, & &1.slug)
      assert "elixirconf" in slugs
      refute "yow" in slugs
    end
  end

  describe "get_event_series_by_slug/1" do
    test "returns the series" do
      {:ok, series} = Events.create_event_series(@valid_series_attrs)
      assert Events.get_event_series_by_slug("elixirconf").id == series.id
    end
  end

  describe "list_upcoming_events/0" do
    test "returns future events excluding cancelled/completed" do
      future_date = Date.add(Date.utc_today(), 30)

      {:ok, _upcoming} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "upcoming",
            start_date: future_date,
            end_date: Date.add(future_date, 2),
            status: :confirmed
        })

      {:ok, _past} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "past",
            start_date: ~D[2020-01-01],
            end_date: ~D[2020-01-02]
        })

      {:ok, _cancelled} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "cancelled",
            start_date: future_date,
            end_date: Date.add(future_date, 1),
            status: :cancelled
        })

      upcoming = Events.list_upcoming_events()
      assert [%{slug: "upcoming"}] = upcoming
    end

    test "returns all kinds including meetups when no kinds filter" do
      future_date = Date.add(Date.utc_today(), 30)

      {:ok, _conference} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "conf-upcoming",
            start_date: future_date,
            end_date: Date.add(future_date, 2)
        })

      {:ok, _meetup} =
        Events.create_event(%{
          @valid_event_attrs
          | name: "Braga BEAM #8",
            slug: "meetup-upcoming",
            kind: :meetup,
            start_date: future_date,
            end_date: future_date
        })

      upcoming = Events.list_upcoming_events()
      kinds = Enum.map(upcoming, & &1.kind)
      assert :conference in kinds
      assert :meetup in kinds
    end

    test "filters by kinds when specified" do
      future_date = Date.add(Date.utc_today(), 30)

      {:ok, _conference} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "conf-upcoming",
            start_date: future_date,
            end_date: Date.add(future_date, 2)
        })

      {:ok, _meetup} =
        Events.create_event(%{
          @valid_event_attrs
          | name: "Braga BEAM #8",
            slug: "meetup-upcoming",
            kind: :meetup,
            start_date: future_date,
            end_date: future_date
        })

      filtered = Events.list_upcoming_events(kinds: [:conference, :summit])
      kinds = Enum.map(filtered, & &1.kind)
      assert :conference in kinds
      refute :meetup in kinds
    end

    test "excludes events from unlisted series" do
      {:ok, unlisted} =
        Events.create_event_series(%{
          name: "YOW!",
          slug: "yow",
          kind: :conference,
          listed: false
        })

      future_date = Date.add(Date.utc_today(), 30)

      {:ok, _} =
        Events.create_event(
          %{
            @valid_event_attrs
            | slug: "yow-upcoming",
              start_date: future_date,
              end_date: Date.add(future_date, 2),
              status: :confirmed
          }
          |> Map.put(:event_series_id, unlisted.id)
        )

      assert [] = Events.list_upcoming_events()
    end
  end

  describe "list_past_events/0" do
    test "returns past events or completed events" do
      {:ok, _past} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "past-event",
            start_date: ~D[2020-01-01],
            end_date: ~D[2020-01-02]
        })

      future_date = Date.add(Date.utc_today(), 30)

      {:ok, _future} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "future-event",
            start_date: future_date,
            end_date: Date.add(future_date, 2)
        })

      past = Events.list_past_events()
      assert [%{slug: "past-event"}] = past
    end

    test "excludes events from unlisted series" do
      {:ok, unlisted} =
        Events.create_event_series(%{
          name: "YOW!",
          slug: "yow",
          kind: :conference,
          listed: false
        })

      {:ok, _} =
        Events.create_event(
          %{
            @valid_event_attrs
            | slug: "yow-past",
              start_date: ~D[2020-01-01],
              end_date: ~D[2020-01-02]
          }
          |> Map.put(:event_series_id, unlisted.id)
        )

      assert [] = Events.list_past_events()
    end
  end

  describe "count_events/0" do
    test "returns the number of events" do
      assert Events.count_events() == 0
      {:ok, _} = Events.create_event(@valid_event_attrs)
      assert Events.count_events() == 1
    end
  end

  describe "list_events_for_series/2" do
    test "returns events belonging to a series" do
      {:ok, series} = Events.create_event_series(@valid_series_attrs)

      {:ok, _} =
        Events.create_event(Map.put(@valid_event_attrs, :event_series_id, series.id))

      {:ok, _} =
        Events.create_event(%{
          @valid_event_attrs
          | slug: "other-event"
        })

      events = Events.list_events_for_series(series.id)
      assert [%{slug: "elixirconf-us-2025"}] = events
    end
  end

  describe "upsert_event_series/1" do
    test "inserts a new series" do
      assert {:ok, series} = Events.upsert_event_series(@valid_series_attrs)
      assert series.name == "ElixirConf"
    end

    test "updates an existing series by slug" do
      {:ok, _} = Events.upsert_event_series(@valid_series_attrs)

      {:ok, updated} =
        Events.upsert_event_series(%{
          name: "ElixirConf Updated",
          slug: "elixirconf",
          kind: :conference
        })

      assert updated.name == "ElixirConf Updated"
    end
  end

  describe "upsert_event/1" do
    test "inserts a new event" do
      assert {:ok, event} = Events.upsert_event(@valid_event_attrs)
      assert event.name == "ElixirConf US 2025"
    end

    test "updates an existing event by slug" do
      {:ok, _} = Events.upsert_event(@valid_event_attrs)

      {:ok, updated} =
        Events.upsert_event(Map.put(@valid_event_attrs, :location, "Updated Location"))

      assert updated.location == "Updated Location"
      assert [_only_one] = Events.list_events()
    end
  end

  describe "replace_event_links/2" do
    test "replaces all links for an event" do
      {:ok, event} = Events.create_event(@valid_event_attrs)
      Events.create_event_link(%{event_id: event.id, kind: :other, url: "https://old.com"})

      {:ok, links} =
        Events.replace_event_links(event.id, [
          %{kind: :code_of_conduct, url: "https://new.com/coc"},
          %{kind: :playlist, url: "https://new.com/playlist"}
        ])

      assert length(links) == 2
    end

    test "clears links when given empty list" do
      {:ok, event} = Events.create_event(@valid_event_attrs)
      Events.create_event_link(%{event_id: event.id, kind: :other, url: "https://old.com"})
      {:ok, links} = Events.replace_event_links(event.id, [])
      assert links == []
    end
  end

  describe "replace_event_roles/2" do
    test "replaces all roles for an event" do
      {:ok, event} = Events.create_event(@valid_event_attrs)
      Events.create_event_role(%{event_id: event.id, name: "Old", role: :organizer})

      {:ok, roles} =
        Events.replace_event_roles(event.id, [
          %{name: "Alice", role: :organizer, position: 1},
          %{name: "Bob", role: :mc, position: 2}
        ])

      assert length(roles) == 2
    end
  end

  describe "event venue association" do
    test "get_event_by_slug/2 preloads venue when requested" do
      venue =
        ElixirEvents.DataFixtures.venue_fixture(%{
          name: "Test Center",
          slug: "test-center",
          latitude: Decimal.new("32.94"),
          longitude: Decimal.new("-97.07")
        })

      series = ElixirEvents.DataFixtures.event_series_fixture()
      event = ElixirEvents.DataFixtures.event_fixture(series, %{venue_id: venue.id})

      loaded = Events.get_event_by_slug(event.slug, preload: [:venue])
      assert loaded.venue.name == "Test Center"
      assert Decimal.equal?(loaded.venue.latitude, Decimal.new("32.94"))
    end
  end
end
