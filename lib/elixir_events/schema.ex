defmodule ElixirEvents.Schema do
  @moduledoc false

  @doc """
  When used, this module:

  1. Sets up Ecto.Schema
  2. Sets UTC datetime timestamps with microseconds
  3. Imports Ecto.Changeset
  4. Aliases common modules
  """
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @timestamps_opts type: :utc_datetime_usec

      import Ecto.Changeset

      alias ElixirEvents.Slug
    end
  end
end
