defmodule ElixirEvents.Events.Event do
  @moduledoc false

  use ElixirEvents.Schema

  alias ElixirEvents.Embeds.SocialLink

  @kinds [:conference, :meetup, :retreat, :hackathon, :summit, :workshop]
  @statuses [:announced, :confirmed, :cancelled, :completed]
  @formats [:in_person, :online, :hybrid]

  @permitted ~w(name slug description kind status format start_date end_date timezone language location website tickets_url banner_url color venue_id event_series_id)a
  @required ~w(name slug kind status format start_date end_date timezone)a

  schema "events" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :kind, Ecto.Enum, values: @kinds
    field :status, Ecto.Enum, values: @statuses
    field :format, Ecto.Enum, values: @formats
    field :start_date, :date
    field :end_date, :date
    field :timezone, :string
    field :language, :string, default: "en"
    field :location, :string
    field :website, :string
    field :tickets_url, :string
    field :banner_url, :string
    field :color, :string
    field :venue_id, :integer

    embeds_many :social_links, SocialLink, on_replace: :delete

    belongs_to :event_series, ElixirEvents.Events.EventSeries
    has_many :event_links, ElixirEvents.Events.EventLink
    has_many :event_roles, ElixirEvents.Events.EventRole
    has_many :talks, ElixirEvents.Talks.Talk
    has_many :cfps, ElixirEvents.Submissions.CFP, foreign_key: :event_id

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, @permitted)
    |> Slug.maybe_generate_slug()
    |> validate_required(@required)
    |> Slug.validate_slug_format()
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:event_series_id)
    |> cast_embed(:social_links, with: &SocialLink.changeset/2)
  end
end
