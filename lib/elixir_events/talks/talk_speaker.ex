defmodule ElixirEvents.Talks.TalkSpeaker do
  @moduledoc false

  use ElixirEvents.Schema

  @roles [:speaker, :moderator, :panelist]

  @permitted ~w(talk_id profile_id role position)a
  @required ~w(talk_id profile_id)a

  schema "talk_speakers" do
    field :role, Ecto.Enum, values: @roles, default: :speaker
    field :position, :integer

    belongs_to :talk, ElixirEvents.Talks.Talk
    belongs_to :profile, ElixirEvents.Profiles.Profile

    timestamps()
  end

  def changeset(talk_speaker, attrs) do
    talk_speaker
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:talk_id)
    |> unique_constraint([:talk_id, :profile_id])
  end
end
