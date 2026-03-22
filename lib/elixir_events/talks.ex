defmodule ElixirEvents.Talks do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Repo
  alias ElixirEvents.Talks.{Recording, Talk, TalkLink, TalkSpeaker}

  def list_talks(opts \\ []) do
    from(t in Talk,
      join: e in assoc(t, :event),
      as: :event
    )
    |> maybe_filter(opts[:filter])
    |> maybe_sort(opts[:sort])
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def paginate_talks(opts \\ []) do
    from(t in Talk,
      join: e in assoc(t, :event),
      as: :event
    )
    |> maybe_filter(opts[:filter])
    |> maybe_sort(opts[:sort])
    |> maybe_preload(opts[:preload])
    |> Repo.paginate(page: opts[:page], per_page: opts[:per_page] || 36)
  end

  def list_talks_for_profile(profile_id, opts \\ []) do
    from(t in Talk,
      join: ts in assoc(t, :talk_speakers),
      where: ts.profile_id == ^profile_id,
      order_by: [desc: t.inserted_at]
    )
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  def list_talks_for_event(event_id) do
    Talk |> where(event_id: ^event_id) |> Repo.all()
  end

  def count_talks do
    Repo.aggregate(Talk, :count)
  end

  def get_talk_by_slug(event_id, slug) do
    Repo.get_by(Talk, event_id: event_id, slug: slug)
  end

  def get_talk_by_event_and_slug(event_slug, talk_slug, opts \\ []) do
    from(t in Talk,
      join: e in assoc(t, :event),
      where: e.slug == ^event_slug and t.slug == ^talk_slug
    )
    |> maybe_preload(opts[:preload])
    |> Repo.one()
  end

  def create_talk(attrs) do
    %Talk{}
    |> Talk.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_talk(attrs) do
    %Talk{}
    |> Talk.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:event_id, :slug],
      returning: true
    )
  end

  def create_recording(attrs) do
    %Recording{}
    |> Recording.changeset(attrs)
    |> Repo.insert()
  end

  def create_talk_speaker(attrs) do
    %TalkSpeaker{}
    |> TalkSpeaker.changeset(attrs)
    |> Repo.insert()
  end

  def create_talk_link(attrs) do
    %TalkLink{}
    |> TalkLink.changeset(attrs)
    |> Repo.insert()
  end

  def replace_recordings(talk_id, recordings_attrs) do
    Repo.transaction(fn ->
      from(r in Recording, where: r.talk_id == ^talk_id) |> Repo.delete_all()

      Enum.map(recordings_attrs, fn attrs ->
        %Recording{}
        |> Recording.changeset(Map.put(attrs, :talk_id, talk_id))
        |> Repo.insert(
          on_conflict: {:replace, [:talk_id, :url, :updated_at]},
          conflict_target: [:provider, :external_id],
          returning: true
        )
        |> case do
          {:ok, rec} -> rec
          {:error, _} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end)
  end

  def replace_talk_speakers(talk_id, speakers_attrs) do
    Repo.transaction(fn ->
      from(ts in TalkSpeaker, where: ts.talk_id == ^talk_id) |> Repo.delete_all()

      Enum.flat_map(speakers_attrs, fn attrs ->
        case create_talk_speaker(Map.put(attrs, :talk_id, talk_id)) do
          {:ok, ts} -> [ts]
          {:error, _} -> []
        end
      end)
    end)
  end

  defp maybe_filter(queryable, "published") do
    recording_ids = from(r in Recording, select: r.talk_id)
    from(t in queryable, where: t.id in subquery(recording_ids))
  end

  defp maybe_filter(queryable, "scheduled") do
    from(t in queryable,
      left_join: r in assoc(t, :recordings),
      where: is_nil(r.id)
    )
  end

  defp maybe_filter(queryable, _), do: queryable

  defp maybe_sort(queryable, "oldest"),
    do: from([t, event: e] in queryable, order_by: [asc: e.start_date, asc: t.title])

  defp maybe_sort(queryable, "title"), do: from(t in queryable, order_by: [asc: t.title])

  defp maybe_sort(queryable, _),
    do: from([t, event: e] in queryable, order_by: [desc: e.start_date, asc: t.title])

  defp maybe_preload(queryable, nil), do: queryable
  defp maybe_preload(queryable, preloads), do: from(q in queryable, preload: ^preloads)

  defp maybe_limit(queryable, nil), do: queryable
  defp maybe_limit(queryable, limit), do: from(q in queryable, limit: ^limit)

  def replace_talk_links(talk_id, links_attrs) do
    Repo.transaction(fn ->
      from(tl in TalkLink, where: tl.talk_id == ^talk_id) |> Repo.delete_all()

      Enum.flat_map(links_attrs, fn attrs ->
        case create_talk_link(Map.put(attrs, :talk_id, talk_id)) do
          {:ok, link} -> [link]
          {:error, _} -> []
        end
      end)
    end)
  end
end
