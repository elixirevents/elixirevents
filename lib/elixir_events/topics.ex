defmodule ElixirEvents.Topics do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Repo
  alias ElixirEvents.Topics.{EventTopic, SessionTopic, TalkTopic, Topic, WorkshopTopic}

  def list_topics(opts \\ []) do
    Topic
    |> maybe_with_counts(opts[:with_counts])
    |> maybe_search(opts[:search])
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def count_topics do
    Repo.aggregate(Topic, :count)
  end

  def get_topic_by_slug(slug) do
    Repo.get_by(Topic, slug: slug)
  end

  def list_talks_for_topic(topic_id, opts \\ []) do
    preloads = opts[:preload] || []

    from(t in ElixirEvents.Talks.Talk,
      join: tt in TalkTopic,
      on: tt.talk_id == t.id,
      where: tt.topic_id == ^topic_id,
      join: e in assoc(t, :event),
      order_by: [desc: e.start_date, asc: t.title],
      preload: ^preloads
    )
    |> Repo.all()
  end

  def create_topic(attrs) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert_and_index()
  end

  def upsert_topic(attrs) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert_and_index(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :slug,
      returning: true
    )
  end

  defp maybe_with_counts(queryable, true) do
    from(t in queryable,
      left_join: tt in TalkTopic,
      on: tt.topic_id == t.id,
      left_join: talk in ElixirEvents.Talks.Talk,
      on: talk.id == tt.talk_id,
      group_by: t.id,
      select_merge: %{
        event_count: count(talk.event_id, :distinct),
        talk_count: count(tt.id, :distinct)
      }
    )
  end

  defp maybe_with_counts(queryable, _), do: queryable

  defp maybe_search(queryable, nil), do: queryable
  defp maybe_search(queryable, ""), do: queryable

  defp maybe_search(queryable, q) do
    pattern = "%#{q}%"
    from(t in queryable, where: ilike(t.name, ^pattern))
  end

  def tag_event(event_id, topic_id) do
    %EventTopic{}
    |> EventTopic.changeset(%{event_id: event_id, topic_id: topic_id})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:event_id, :topic_id])
  end

  def tag_talk(talk_id, topic_id) do
    %TalkTopic{}
    |> TalkTopic.changeset(%{talk_id: talk_id, topic_id: topic_id})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:talk_id, :topic_id])
  end

  def tag_session(session_id, topic_id) do
    %SessionTopic{}
    |> SessionTopic.changeset(%{session_id: session_id, topic_id: topic_id})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:session_id, :topic_id])
  end

  def tag_workshop(workshop_id, topic_id) do
    %WorkshopTopic{}
    |> WorkshopTopic.changeset(%{workshop_id: workshop_id, topic_id: topic_id})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:workshop_id, :topic_id])
  end
end
