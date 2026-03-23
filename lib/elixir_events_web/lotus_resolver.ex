defmodule ElixirEventsWeb.LotusResolver do
  @moduledoc false
  @behaviour Lotus.Web.Resolver

  @impl true
  def resolve_user(conn) do
    case conn.assigns[:current_scope] do
      %{user: user} -> user
      _ -> nil
    end
  end

  @impl true
  def resolve_access(user) do
    case user do
      %{role: :admin} -> :all
      %{} -> :read_only
      nil -> :read_only
    end
  end
end
