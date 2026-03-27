defmodule ElixirEvents.Talks.Recording do
  @moduledoc false

  use ElixirEvents.Schema

  @providers [:youtube, :vimeo, :other]

  def providers, do: @providers

  @permitted ~w(talk_id provider external_id url duration published_at thumbnail_url)a
  @required ~w(talk_id provider url)a

  schema "recordings" do
    field :provider, Ecto.Enum, values: @providers
    field :external_id, :string
    field :url, :string
    field :duration, :integer
    field :published_at, :utc_datetime_usec
    field :thumbnail_url, :string

    belongs_to :talk, ElixirEvents.Talks.Talk

    timestamps()
  end

  def changeset(recording, attrs) do
    recording
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:talk_id)
    |> unique_constraint([:provider, :external_id], name: :recordings_provider_external_id_index)
  end
end
