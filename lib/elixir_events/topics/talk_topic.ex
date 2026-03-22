defmodule ElixirEvents.Topics.TalkTopic do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(talk_id topic_id)a
  @required ~w(talk_id topic_id)a

  schema "talk_topics" do
    field :talk_id, :integer
    belongs_to :topic, ElixirEvents.Topics.Topic

    timestamps()
  end

  def changeset(talk_topic, attrs) do
    talk_topic
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> unique_constraint([:talk_id, :topic_id])
    |> foreign_key_constraint(:topic_id)
  end
end
