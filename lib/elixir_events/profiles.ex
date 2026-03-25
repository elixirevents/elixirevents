defmodule ElixirEvents.Profiles do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Profiles.Profile
  alias ElixirEvents.Repo

  def list_profiles(opts \\ []) do
    Profile
    |> maybe_filter_speakers(opts[:speakers_only])
    |> maybe_with_talk_count(opts[:with_talk_count])
    |> maybe_order(opts[:order_by])
    |> maybe_limit(opts[:limit])
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  def paginate_profiles(opts \\ []) do
    Profile
    |> maybe_filter_speakers(opts[:speakers_only])
    |> maybe_search(opts[:search])
    |> maybe_with_talk_count(opts[:with_talk_count])
    |> maybe_order(opts[:order_by] || :name_asc)
    |> maybe_preload(opts[:preload])
    |> Repo.paginate(page: opts[:page], per_page: opts[:per_page] || 36)
  end

  def count_profiles(opts \\ []) do
    Profile
    |> maybe_filter_speakers(opts[:speakers_only])
    |> Repo.aggregate(:count)
  end

  def get_profile(id), do: Repo.get(Profile, id)

  def get_profile_by_handle(handle, opts \\ []) do
    Profile
    |> maybe_preload(opts[:preload])
    |> Repo.get_by(handle: handle)
  end

  def get_profile_by_handle!(handle, opts \\ []) do
    Profile
    |> maybe_preload(opts[:preload])
    |> Repo.get_by!(handle: handle)
  end

  def get_profile_by_handle_with_owner_status(handle) do
    case Repo.get_by(Profile, handle: handle) do
      nil -> nil
      %Profile{user_id: nil} = profile -> {:unclaimed, profile}
      %Profile{} = profile -> {:claimed, profile}
    end
  end

  def suggest_available_handle(handle) do
    candidates = [handle | Enum.map(1..10, &"#{handle}#{&1}")]

    existing =
      from(p in Profile, where: p.handle in ^candidates, select: p.handle)
      |> Repo.all()
      |> MapSet.new()

    Enum.find(candidates, fn candidate -> candidate not in existing end)
  end

  def create_profile(attrs) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert_and_index()
  end

  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update_and_index()
  end

  def update_profile_as_owner(%Profile{} = profile, attrs) do
    profile
    |> Profile.owner_changeset(attrs)
    |> Repo.update_and_index()
  end

  def get_profile_for_user(user_id) do
    Repo.get_by(Profile, user_id: user_id)
  end

  def create_profile_for_user(user, attrs) do
    %Profile{}
    |> Profile.changeset(Map.put(attrs, :user_id, user.id))
    |> Repo.insert_and_index()
  end

  def upsert_profile(attrs) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert_and_index(
      on_conflict: {:replace_all_except, [:id, :user_id, :inserted_at]},
      conflict_target: :handle,
      returning: true
    )
  end

  defp maybe_filter_speakers(queryable, true),
    do: from(q in queryable, where: q.is_speaker == true)

  defp maybe_filter_speakers(queryable, _), do: queryable

  defp maybe_search(queryable, nil), do: queryable
  defp maybe_search(queryable, ""), do: queryable

  defp maybe_search(queryable, q) do
    pattern = "%#{q}%"
    from(p in queryable, where: ilike(p.name, ^pattern))
  end

  defp maybe_with_talk_count(queryable, true) do
    from(p in queryable,
      left_join: ts in assoc(p, :talk_speakers),
      group_by: p.id,
      select_merge: %{talk_count: count(ts.id)}
    )
  end

  defp maybe_with_talk_count(queryable, _), do: queryable

  defp maybe_order(queryable, :talk_count_desc) do
    from(q in queryable, order_by: [desc: count(q.id), asc: q.name])
  end

  defp maybe_order(queryable, :name_asc), do: from(q in queryable, order_by: [asc: q.name])
  defp maybe_order(queryable, _), do: queryable

  defp maybe_limit(queryable, nil), do: queryable
  defp maybe_limit(queryable, limit), do: from(q in queryable, limit: ^limit)

  defp maybe_preload(queryable, nil), do: queryable
  defp maybe_preload(queryable, preloads), do: from(q in queryable, preload: ^preloads)
end
