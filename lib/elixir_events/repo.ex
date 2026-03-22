defmodule ElixirEvents.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :elixir_events,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query

  @doc """
  Simple offset-based pagination. Returns a map with entries, page info, and total count.
  Works with queries that have group_by by wrapping in a subquery for counting.
  """
  def paginate(queryable, opts \\ []) do
    page = max(opts[:page] || 1, 1)
    per_page = opts[:per_page] || 36

    total_count = count_query(queryable)
    total_pages = max(ceil(total_count / per_page), 1)
    page = min(page, total_pages)

    entries =
      queryable
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> all()

    %{
      entries: entries,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }
  end

  defp count_query(queryable) do
    queryable
    |> exclude(:preload)
    |> exclude(:order_by)
    |> exclude(:select)
    |> subquery()
    |> select(count())
    |> one()
  end
end
