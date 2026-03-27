defmodule ElixirEvents.TopicsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Topics

  @valid_attrs %{name: "LiveView", slug: "liveview", description: "Phoenix LiveView"}

  describe "create_topic/1" do
    test "creates a topic with valid attrs" do
      assert {:ok, topic} = Topics.create_topic(@valid_attrs)
      assert topic.name == "LiveView"
    end

    test "requires name and slug" do
      assert {:error, changeset} = Topics.create_topic(%{})
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).slug
    end

    test "enforces unique slug" do
      {:ok, _} = Topics.create_topic(@valid_attrs)
      assert {:error, changeset} = Topics.create_topic(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "list_topics/0" do
    test "returns all topics" do
      {:ok, topic} = Topics.create_topic(@valid_attrs)
      assert [found] = Topics.list_topics()
      assert found.id == topic.id
    end
  end

  describe "count_topics/0" do
    test "returns the number of topics" do
      assert Topics.count_topics() == 0
      {:ok, _} = Topics.create_topic(@valid_attrs)
      assert Topics.count_topics() == 1
    end
  end

  describe "get_topic_by_slug/1" do
    test "returns a topic by slug" do
      {:ok, topic} = Topics.create_topic(@valid_attrs)
      assert Topics.get_topic_by_slug("liveview").id == topic.id
    end

    test "returns nil for non-existent slug" do
      assert Topics.get_topic_by_slug("nonexistent") == nil
    end
  end

  describe "list_talks_for_topic/2" do
    test "returns talks tagged with a topic" do
      {:ok, topic} = Topics.create_topic(%{name: "Ecto", slug: "ecto"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "Conf",
          slug: "conf-topic-talks",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2025-01-01],
          end_date: ~D[2025-01-02],
          timezone: "UTC"
        })

      {:ok, talk} =
        ElixirEvents.Talks.create_talk(%{
          event_id: event.id,
          title: "Ecto Deep Dive",
          slug: "ecto-deep-dive",
          kind: :talk
        })

      {:ok, _} = Topics.tag_talk(talk.id, topic.id)

      talks = Topics.list_talks_for_topic(topic.id)
      assert [%{title: "Ecto Deep Dive"}] = talks
    end
  end

  describe "tag_event/2" do
    test "tags an event with a topic" do
      {:ok, topic} = Topics.create_topic(%{name: "Elixir", slug: "elixir"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "Conf",
          slug: "conf",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2025-01-01],
          end_date: ~D[2025-01-02],
          timezone: "UTC"
        })

      assert {:ok, _} = Topics.tag_event(event.id, topic.id)
    end

    test "prevents duplicate tagging" do
      {:ok, topic} = Topics.create_topic(%{name: "Elixir", slug: "elixir"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "Conf",
          slug: "conf",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2025-01-01],
          end_date: ~D[2025-01-02],
          timezone: "UTC"
        })

      {:ok, _} = Topics.tag_event(event.id, topic.id)
      assert {:ok, _} = Topics.tag_event(event.id, topic.id)
    end
  end

  describe "tag_talk/2" do
    test "tags a talk with a topic" do
      {:ok, topic} = Topics.create_topic(%{name: "LiveView", slug: "liveview"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "Conf",
          slug: "conf2",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2025-01-01],
          end_date: ~D[2025-01-02],
          timezone: "UTC"
        })

      {:ok, talk} =
        ElixirEvents.Talks.create_talk(%{
          event_id: event.id,
          title: "Talk",
          slug: "talk",
          kind: :talk
        })

      assert {:ok, _} = Topics.tag_talk(talk.id, topic.id)
    end
  end

  describe "tag_session/2" do
    test "tags a session with a topic" do
      {:ok, topic} = Topics.create_topic(%{name: "OTP", slug: "otp"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "Conf",
          slug: "conf3",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2025-01-01],
          end_date: ~D[2025-01-02],
          timezone: "UTC"
        })

      {:ok, session} =
        ElixirEvents.Program.create_session(%{
          event_id: event.id,
          title: "Break",
          kind: :break
        })

      assert {:ok, _} = Topics.tag_session(session.id, topic.id)
    end
  end

  describe "upsert_topic/1" do
    test "inserts a new topic" do
      assert {:ok, topic} = Topics.upsert_topic(%{name: "Elixir", slug: "elixir"})
      assert topic.name == "Elixir"
    end

    test "updates an existing topic by slug" do
      {:ok, _} = Topics.upsert_topic(%{name: "Elixir", slug: "elixir"})

      {:ok, updated} =
        Topics.upsert_topic(%{name: "Elixir Lang", slug: "elixir", description: "The language"})

      assert updated.name == "Elixir Lang"
      assert updated.description == "The language"
      assert [_only_one] = Topics.list_topics()
    end
  end

  describe "tag_workshop/2" do
    test "tags a workshop with a topic" do
      {:ok, topic} = Topics.create_topic(%{name: "LiveView", slug: "liveview-ws"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "Conf",
          slug: "conf-ws",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-20],
          timezone: "Europe/Stockholm"
        })

      {:ok, workshop} =
        ElixirEvents.Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "LiveView Workshop",
          slug: "liveview-workshop",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      assert {:ok, _} = Topics.tag_workshop(workshop.id, topic.id)
    end

    test "is idempotent — second call succeeds silently" do
      {:ok, topic} = Topics.create_topic(%{name: "OTP", slug: "otp-ws"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "Conf",
          slug: "conf-ws2",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-20],
          timezone: "Europe/Stockholm"
        })

      {:ok, workshop} =
        ElixirEvents.Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "OTP Workshop",
          slug: "otp-workshop",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      assert {:ok, _} = Topics.tag_workshop(workshop.id, topic.id)
      assert {:ok, _} = Topics.tag_workshop(workshop.id, topic.id)
    end
  end

  describe "tag_event/2 idempotent" do
    test "second tag_event call succeeds silently" do
      {:ok, topic} = Topics.create_topic(%{name: "Test", slug: "test-idem"})

      {:ok, event} =
        ElixirEvents.Events.create_event(%{
          name: "C",
          slug: "c-idem",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: ~D[2025-01-01],
          end_date: ~D[2025-01-02],
          timezone: "UTC"
        })

      assert {:ok, _} = Topics.tag_event(event.id, topic.id)
      assert {:ok, _} = Topics.tag_event(event.id, topic.id)
    end
  end
end
