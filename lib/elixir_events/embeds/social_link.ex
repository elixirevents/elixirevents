defmodule ElixirEvents.Embeds.SocialLink do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @platforms [
    :website,
    :twitter,
    :mastodon,
    :bluesky,
    :github,
    :linkedin,
    :instagram,
    :youtube,
    :meetup
  ]

  def platforms, do: @platforms

  @primary_key false
  embedded_schema do
    field :platform, Ecto.Enum, values: @platforms
    field :url, :string
    field :label, :string
  end

  def changeset(social_link, attrs) do
    social_link
    |> cast(attrs, [:platform, :url, :label])
    |> validate_required([:platform, :url])
  end
end
