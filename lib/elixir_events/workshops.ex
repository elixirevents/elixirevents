defmodule ElixirEvents.Workshops do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Repo
  alias ElixirEvents.Workshops.{Workshop, WorkshopTrainer}

  def list_workshops_for_event(event_id, opts \\ []) do
    from(w in Workshop,
      where: w.event_id == ^event_id,
      order_by: [asc: w.start_date, asc: w.title]
    )
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  def get_workshop_by_event_and_slug(event_slug, workshop_slug, opts \\ []) do
    from(w in Workshop,
      join: e in assoc(w, :event),
      where: e.slug == ^event_slug and w.slug == ^workshop_slug
    )
    |> maybe_preload(opts[:preload])
    |> Repo.one()
  end

  def get_workshop_by_slug(event_id, slug) do
    Repo.get_by(Workshop, event_id: event_id, slug: slug)
  end

  def upsert_workshop(attrs) do
    %Workshop{}
    |> Workshop.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:event_id, :slug],
      returning: true
    )
  end

  def delete_orphaned_workshops(event_id, yaml_slugs) do
    from(w in Workshop,
      where: w.event_id == ^event_id and w.slug not in ^yaml_slugs
    )
    |> Repo.delete_all()
  end

  def replace_workshop_trainers(workshop_id, trainers_attrs) do
    Repo.transaction(fn ->
      from(wt in WorkshopTrainer, where: wt.workshop_id == ^workshop_id) |> Repo.delete_all()

      Enum.flat_map(trainers_attrs, fn attrs ->
        case create_workshop_trainer(Map.put(attrs, :workshop_id, workshop_id)) do
          {:ok, wt} -> [wt]
          {:error, _} -> []
        end
      end)
    end)
  end

  defp create_workshop_trainer(attrs) do
    %WorkshopTrainer{}
    |> WorkshopTrainer.changeset(attrs)
    |> Repo.insert()
  end

  defp maybe_preload(queryable, nil), do: queryable
  defp maybe_preload(queryable, preloads), do: from(q in queryable, preload: ^preloads)
end
