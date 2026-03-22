defmodule ElixirEvents.Submissions.CFP do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(event_id name url description open_date close_date)a
  @required ~w(event_id url)a

  schema "cfps" do
    field :event_id, :integer
    field :name, :string
    field :url, :string
    field :description, :string
    field :open_date, :date
    field :close_date, :date

    timestamps()
  end

  def changeset(cfp, attrs) do
    cfp
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
