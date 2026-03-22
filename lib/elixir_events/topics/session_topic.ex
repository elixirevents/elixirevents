defmodule ElixirEvents.Topics.SessionTopic do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(session_id topic_id)a
  @required ~w(session_id topic_id)a

  schema "session_topics" do
    field :session_id, :integer
    belongs_to :topic, ElixirEvents.Topics.Topic

    timestamps()
  end

  def changeset(session_topic, attrs) do
    session_topic
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> unique_constraint([:session_id, :topic_id])
    |> foreign_key_constraint(:topic_id)
  end
end
