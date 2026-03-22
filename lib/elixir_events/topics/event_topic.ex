defmodule ElixirEvents.Topics.EventTopic do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(event_id topic_id)a
  @required ~w(event_id topic_id)a

  schema "event_topics" do
    field :event_id, :integer
    belongs_to :topic, ElixirEvents.Topics.Topic

    timestamps()
  end

  def changeset(event_topic, attrs) do
    event_topic
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> unique_constraint([:event_id, :topic_id])
    |> foreign_key_constraint(:topic_id)
  end
end
