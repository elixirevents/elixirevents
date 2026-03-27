defmodule ElixirEvents.Workshops.WorkshopAgendaDay do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :day_number, :integer
    field :title, :string
    field :start_time, :time
    field :end_time, :time
    field :items, {:array, :string}, default: []
  end

  def changeset(agenda_day, attrs) do
    agenda_day
    |> cast(attrs, [:day_number, :title, :start_time, :end_time, :items])
    |> validate_required([:day_number])
  end
end
