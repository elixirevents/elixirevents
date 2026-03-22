defmodule ElixirEvents.Events.EventLink do
  @moduledoc false

  use ElixirEvents.Schema

  @kinds [:playlist, :schedule, :code_of_conduct, :other]

  @permitted ~w(event_id kind url label)a
  @required ~w(event_id kind url)a

  schema "event_links" do
    field :kind, Ecto.Enum, values: @kinds
    field :url, :string
    field :label, :string

    belongs_to :event, ElixirEvents.Events.Event

    timestamps()
  end

  def changeset(event_link, attrs) do
    event_link
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:event_id)
  end
end
