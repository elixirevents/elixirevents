defmodule ElixirEvents.Topics.Topic do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(name slug description)a
  @required ~w(name slug)a

  schema "topics" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :event_count, :integer, virtual: true
    field :talk_count, :integer, virtual: true

    has_many :event_topics, ElixirEvents.Topics.EventTopic
    has_many :talk_topics, ElixirEvents.Topics.TalkTopic

    timestamps()
  end

  def changeset(topic, attrs) do
    topic
    |> cast(attrs, @permitted)
    |> Slug.maybe_generate_slug()
    |> validate_required(@required)
    |> Slug.validate_slug_format()
    |> unique_constraint(:slug)
  end
end
