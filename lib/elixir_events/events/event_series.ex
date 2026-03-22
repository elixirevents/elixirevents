defmodule ElixirEvents.Events.EventSeries do
  @moduledoc false

  use ElixirEvents.Schema

  alias ElixirEvents.Embeds.SocialLink

  @kinds [:conference, :meetup, :retreat, :hackathon, :summit, :workshop]
  @frequencies [:yearly, :monthly, :quarterly, :biannual, :irregular, :once]

  @permitted ~w(name slug description kind frequency language website color ended)a
  @required ~w(name slug kind)a

  schema "event_series" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :kind, Ecto.Enum, values: @kinds
    field :frequency, Ecto.Enum, values: @frequencies
    field :language, :string, default: "en"
    field :website, :string
    field :color, :string
    field :ended, :boolean, default: false

    embeds_many :social_links, SocialLink, on_replace: :delete

    has_many :events, ElixirEvents.Events.Event

    timestamps()
  end

  def changeset(event_series, attrs) do
    event_series
    |> cast(attrs, @permitted)
    |> Slug.maybe_generate_slug()
    |> validate_required(@required)
    |> Slug.validate_slug_format()
    |> unique_constraint(:slug)
    |> cast_embed(:social_links, with: &SocialLink.changeset/2)
  end
end
