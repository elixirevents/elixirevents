defmodule ElixirEvents.Events do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Events.{Event, EventLink, EventRole, EventSeries}
  alias ElixirEvents.Repo

  def list_event_series do
    EventSeries
    |> where([s], s.listed == true)
    |> Repo.all()
  end

  def get_event_series_by_slug(slug) do
    Repo.get_by(EventSeries, slug: slug)
  end

  def create_event_series(attrs) do
    %EventSeries{}
    |> EventSeries.changeset(attrs)
    |> Repo.insert_and_index()
  end

  def upsert_event_series(attrs) do
    %EventSeries{}
    |> EventSeries.changeset(attrs)
    |> Repo.insert_and_index(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :slug,
      returning: true
    )
  end

  def list_events(opts \\ []) do
    Event
    |> listed_events_only()
    |> maybe_filter_by_kinds(opts[:kinds])
    |> maybe_search(opts[:search])
    |> by_year_desc_date_desc()
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def list_upcoming_events(opts \\ []) do
    today = Date.utc_today()

    Event
    |> listed_events_only()
    |> maybe_filter_by_kinds(opts[:kinds])
    |> maybe_search(opts[:search])
    |> where([e], e.start_date >= ^today)
    |> where([e], e.status not in [:ongoing, :cancelled, :completed])
    |> by_date_asc()
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def list_past_events(opts \\ []) do
    today = Date.utc_today()

    Event
    |> listed_events_only()
    |> maybe_filter_by_kinds(opts[:kinds])
    |> maybe_search(opts[:search])
    |> where([e], e.start_date < ^today or e.status in [:completed, :ongoing])
    |> by_date_desc()
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def start_ongoing_events do
    today = Date.utc_today()

    from(e in Event,
      where: e.start_date <= ^today,
      where: e.end_date >= ^today,
      where: e.status in [:announced, :confirmed]
    )
    |> Repo.update_all(set: [status: :ongoing, updated_at: DateTime.utc_now()])
  end

  def complete_past_events do
    today = Date.utc_today()

    from(e in Event,
      where: e.end_date < ^today,
      where: e.status not in [:completed, :cancelled]
    )
    |> Repo.update_all(set: [status: :completed, updated_at: DateTime.utc_now()])
  end

  def count_events do
    Repo.aggregate(Event, :count)
  end

  def list_events_for_series(series_id, opts \\ []) do
    Event
    |> where([e], e.event_series_id == ^series_id)
    |> order_by([e], desc: e.start_date)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  def get_event_by_slug(slug, opts \\ []) do
    Event
    |> maybe_preload(opts[:preload])
    |> Repo.get_by(slug: slug)
  end

  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert_and_index()
  end

  def upsert_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert_and_index(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :slug,
      returning: true
    )
  end

  def delete_orphaned_events(series_id, yaml_slugs) do
    from(e in Event,
      where: e.event_series_id == ^series_id and e.slug not in ^yaml_slugs
    )
    |> Repo.delete_all()
  end

  def create_event_link(attrs) do
    %EventLink{}
    |> EventLink.changeset(attrs)
    |> Repo.insert()
  end

  def create_event_role(attrs) do
    %EventRole{}
    |> EventRole.changeset(attrs)
    |> Repo.insert()
  end

  def replace_event_links(event_id, links_attrs) do
    Repo.transaction(fn ->
      from(l in EventLink, where: l.event_id == ^event_id) |> Repo.delete_all()

      Enum.map(links_attrs, fn attrs ->
        {:ok, link} = create_event_link(Map.put(attrs, :event_id, event_id))
        link
      end)
    end)
  end

  defp listed_events_only(queryable) do
    from(e in queryable,
      left_join: s in assoc(e, :event_series),
      where: is_nil(s.id) or s.listed == true
    )
  end

  defp by_date_asc(queryable), do: order_by(queryable, [e], asc: e.start_date)
  defp by_date_desc(queryable), do: order_by(queryable, [e], desc: e.start_date)

  defp by_year_desc_date_desc(queryable) do
    from(e in queryable,
      order_by: [desc: fragment("extract(year from ?)", e.start_date), desc: e.start_date]
    )
  end

  defp maybe_filter_by_kinds(queryable, nil), do: queryable
  defp maybe_filter_by_kinds(queryable, []), do: queryable
  defp maybe_filter_by_kinds(queryable, kinds), do: where(queryable, [e], e.kind in ^kinds)

  defp maybe_search(queryable, nil), do: queryable
  defp maybe_search(queryable, ""), do: queryable

  defp maybe_search(queryable, q) do
    pattern = "%#{q}%"
    from(e in queryable, where: ilike(e.name, ^pattern))
  end

  defp maybe_preload(queryable, nil), do: queryable
  defp maybe_preload(queryable, preloads), do: from(q in queryable, preload: ^preloads)

  defp maybe_limit(queryable, nil), do: queryable
  defp maybe_limit(queryable, limit), do: from(q in queryable, limit: ^limit)

  def replace_event_roles(event_id, roles_attrs) do
    Repo.transaction(fn ->
      from(r in EventRole, where: r.event_id == ^event_id) |> Repo.delete_all()

      Enum.map(roles_attrs, fn attrs ->
        {:ok, role} = create_event_role(Map.put(attrs, :event_id, event_id))
        role
      end)
    end)
  end
end
