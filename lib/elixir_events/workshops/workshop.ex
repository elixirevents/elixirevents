defmodule ElixirEvents.Workshops.Workshop do
  @moduledoc false

  use ElixirEvents.Schema

  alias ElixirEvents.Workshops.WorkshopAgendaDay

  @formats [:in_person, :online, :hybrid]

  @permitted ~w(event_id venue_id title slug description format experience_level target_audience language start_date end_date booking_url attendees_only)a
  @required ~w(event_id title slug start_date end_date)a

  schema "workshops" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :format, Ecto.Enum, values: @formats
    field :experience_level, :string
    field :target_audience, :string
    field :language, :string, default: "en"
    field :start_date, :date
    field :end_date, :date
    field :booking_url, :string
    field :attendees_only, :boolean, default: false

    embeds_many :agenda, WorkshopAgendaDay, on_replace: :delete

    belongs_to :event, ElixirEvents.Events.Event
    belongs_to :venue, ElixirEvents.Venues.Venue

    has_many :workshop_trainers, ElixirEvents.Workshops.WorkshopTrainer

    timestamps()
  end

  def changeset(workshop, attrs) do
    workshop
    |> cast(attrs, @permitted)
    |> Slug.maybe_generate_slug(:title)
    |> validate_required(@required)
    |> Slug.validate_slug_format()
    |> unique_constraint(:slug, name: :workshops_event_id_slug_index)
    |> foreign_key_constraint(:event_id)
    |> cast_embed(:agenda, with: &WorkshopAgendaDay.changeset/2)
  end
end
