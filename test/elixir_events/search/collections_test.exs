defmodule ElixirEvents.Search.CollectionsTest do
  use ElixirEvents.DataCase

  alias ElixirEvents.Search.Collections.EventDocument
  alias ElixirEvents.Search.Collections.EventSeriesDocument
  alias ElixirEvents.Search.Collections.ProfileDocument
  alias ElixirEvents.Search.Collections.TalkDocument
  alias ElixirEvents.Search.Collections.TopicDocument
  alias ElixirEvents.Search.Indexer

  import ElixirEvents.DataFixtures

  describe "EventDocument" do
    test "to_search_document/1 produces correct map" do
      series = event_series_fixture()
      event = event_fixture(series)
      doc = EventDocument.to_search_document(event)
      assert doc.id == to_string(event.id)
      assert doc.name == event.name
      assert doc.slug == event.slug
      assert doc.kind == to_string(event.kind)
      assert doc.status == to_string(event.status)
      assert is_integer(doc.start_date)
    end

    test "collection_name/0 returns events" do
      assert EventDocument.collection_name() == "events"
    end

    test "search_schema/0 returns valid schema" do
      schema = EventDocument.search_schema()
      assert schema.name == "events"
      assert is_list(schema.fields)
      assert Enum.any?(schema.fields, &(&1.name == "name" && &1.index == true))
    end
  end

  describe "TalkDocument" do
    test "to_search_document/1 includes denormalized speaker and event names" do
      series = event_series_fixture()
      event = event_fixture(series)
      talk = talk_fixture(event)
      profile = profile_fixture()

      ElixirEvents.Talks.replace_talk_speakers(talk.id, [
        %{profile_id: profile.id, role: :speaker, position: 1}
      ])

      talk = ElixirEvents.Repo.preload(talk, talk_speakers: :profile, event: [])
      doc = TalkDocument.to_search_document(talk)
      assert doc.id == to_string(talk.id)
      assert doc.title == talk.title
      assert doc.event_name == event.name
      assert doc.event_slug == event.slug
      assert is_integer(doc.event_start_date)
      assert profile.name in doc.speaker_names
    end

    test "collection_name/0 returns talks" do
      assert TalkDocument.collection_name() == "talks"
    end
  end

  describe "ProfileDocument" do
    test "to_search_document/1 produces correct map" do
      profile = profile_fixture()
      doc = ProfileDocument.to_search_document(profile)
      assert doc.id == to_string(profile.id)
      assert doc.name == profile.name
      assert doc.handle == profile.handle
      assert doc.is_speaker == profile.is_speaker
    end

    test "collection_name/0 returns profiles" do
      assert ProfileDocument.collection_name() == "profiles"
    end
  end

  describe "TopicDocument" do
    test "to_search_document/1 produces correct map" do
      topic = topic_fixture()
      doc = TopicDocument.to_search_document(topic)
      assert doc.id == to_string(topic.id)
      assert doc.name == topic.name
      assert doc.slug == topic.slug
    end

    test "collection_name/0 returns topics" do
      assert TopicDocument.collection_name() == "topics"
    end
  end

  describe "Indexer.load_record/2 for Profile" do
    test "populates talk_count from talk_speakers association" do
      series = event_series_fixture()
      event = event_fixture(series)
      talk = talk_fixture(event)
      profile = profile_fixture()

      ElixirEvents.Talks.replace_talk_speakers(talk.id, [
        %{profile_id: profile.id, role: :speaker, position: 1}
      ])

      {:ok, loaded} = Indexer.load_record("Profile", profile.id)
      assert loaded.talk_count == 1

      doc = ProfileDocument.to_search_document(loaded)
      assert doc.talk_count == 1
    end

    test "talk_count is 0 when profile has no talks" do
      profile = profile_fixture()

      {:ok, loaded} = Indexer.load_record("Profile", profile.id)
      assert loaded.talk_count == 0
    end
  end

  describe "Indexer.load_record/2 for Topic" do
    test "populates talk_count and event_count from associations" do
      series = event_series_fixture()
      event = event_fixture(series)
      talk = talk_fixture(event)
      topic = topic_fixture()

      ElixirEvents.Topics.tag_talk(talk.id, topic.id)
      ElixirEvents.Topics.tag_event(event.id, topic.id)

      {:ok, loaded} = Indexer.load_record("Topic", topic.id)
      assert loaded.talk_count == 1
      assert loaded.event_count == 1

      doc = TopicDocument.to_search_document(loaded)
      assert doc.talk_count == 1
      assert doc.event_count == 1
    end

    test "counts are 0 when topic has no associations" do
      topic = topic_fixture()

      {:ok, loaded} = Indexer.load_record("Topic", topic.id)
      assert loaded.talk_count == 0
      assert loaded.event_count == 0
    end
  end

  describe "Indexer.load_record/2 for Talk" do
    test "populates event_start_date in search document" do
      series = event_series_fixture()
      event = event_fixture(series, start_date: ~D[2025-06-15])
      talk = talk_fixture(event)

      {:ok, loaded} = Indexer.load_record("Talk", talk.id)
      doc = TalkDocument.to_search_document(loaded)
      assert doc.event_start_date == Date.to_gregorian_days(~D[2025-06-15])
    end
  end

  describe "EventSeriesDocument" do
    test "to_search_document/1 produces correct map" do
      series = event_series_fixture()
      doc = EventSeriesDocument.to_search_document(series)
      assert doc.id == to_string(series.id)
      assert doc.name == series.name
      assert doc.slug == series.slug
    end

    test "collection_name/0 returns event_series" do
      assert EventSeriesDocument.collection_name() == "event_series"
    end
  end
end
