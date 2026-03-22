defmodule ElixirEvents.Submissions do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Repo
  alias ElixirEvents.Submissions.CFP

  def list_cfps(event_id) do
    CFP |> where(event_id: ^event_id) |> Repo.all()
  end

  def create_cfp(attrs) do
    %CFP{}
    |> CFP.changeset(attrs)
    |> Repo.insert()
  end

  def replace_cfps(event_id, cfps_attrs) do
    Repo.transaction(fn ->
      from(c in CFP, where: c.event_id == ^event_id) |> Repo.delete_all()

      Enum.map(cfps_attrs, fn attrs ->
        {:ok, cfp} = create_cfp(Map.put(attrs, :event_id, event_id))
        cfp
      end)
    end)
  end
end
