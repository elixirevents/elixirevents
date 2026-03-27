defmodule ElixirEvents.Talks.Talk do
  @moduledoc false

  use ElixirEvents.Schema

  @kinds [:keynote, :talk, :workshop, :panel, :lightning_talk]
  @levels [:beginner, :intermediate, :advanced]

  def kinds, do: @kinds
  def levels, do: @levels

  @permitted ~w(event_id title slug abstract kind language level duration)a
  @required ~w(event_id title slug kind)a

  schema "talks" do
    field :title, :string
    field :slug, :string
    field :abstract, :string
    field :kind, Ecto.Enum, values: @kinds
    field :language, :string, default: "en"
    field :level, Ecto.Enum, values: @levels
    field :duration, :integer

    belongs_to :event, ElixirEvents.Events.Event

    has_many :recordings, ElixirEvents.Talks.Recording
    has_many :talk_speakers, ElixirEvents.Talks.TalkSpeaker
    has_many :talk_links, ElixirEvents.Talks.TalkLink

    timestamps()
  end

  def changeset(talk, attrs) do
    talk
    |> cast(attrs, @permitted)
    |> Slug.maybe_generate_slug(:title)
    |> validate_required(@required)
    |> Slug.validate_slug_format()
    |> unique_constraint(:slug, name: :talks_event_id_slug_index)
  end
end
