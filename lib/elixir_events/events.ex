defmodule ElixirEvents.Events do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Events.{Event, EventLink, EventRole, EventSeries}
  alias ElixirEvents.Repo

  def list_event_series do
    Repo.all(EventSeries)
  end

  def get_event_series_by_slug(slug) do
    Repo.get_by(EventSeries, slug: slug)
  end

  def create_event_series(attrs) do
    %EventSeries{}
    |> EventSeries.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_event_series(attrs) do
    %EventSeries{}
    |> EventSeries.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :slug,
      returning: true
    )
  end

  def list_events(opts \\ []) do
    Event
    |> order_by([e], desc: e.start_date)
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def list_upcoming_events(opts \\ []) do
    today = Date.utc_today()

    Event
    |> where([e], e.start_date >= ^today)
    |> where([e], e.status not in [:cancelled, :completed])
    |> order_by([e], asc: e.start_date)
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def list_past_events(opts \\ []) do
    today = Date.utc_today()

    Event
    |> where([e], e.start_date < ^today or e.status == :completed)
    |> order_by([e], desc: e.start_date)
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
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
    |> Repo.insert()
  end

  def upsert_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :slug,
      returning: true
    )
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
