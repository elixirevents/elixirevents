defmodule ElixirEvents.Topics.WorkshopTopic do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(workshop_id topic_id)a
  @required ~w(workshop_id topic_id)a

  schema "workshop_topics" do
    field :workshop_id, :integer
    belongs_to :topic, ElixirEvents.Topics.Topic

    timestamps()
  end

  def changeset(workshop_topic, attrs) do
    workshop_topic
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> unique_constraint([:workshop_id, :topic_id])
    |> foreign_key_constraint(:topic_id)
  end
end
