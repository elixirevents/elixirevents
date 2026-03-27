defmodule ElixirEventsWeb.Helpers do
  @moduledoc """
  View helpers for ElixirEvents templates.
  """

  alias ElixirEvents.Colors

  @doc "Get initials from a full name (e.g., 'Jose Valim' -> 'JV')"
  def initials(name) when is_binary(name) do
    parts = String.split(name, ~r/\s+/)

    case parts do
      [single] ->
        single |> String.first() |> String.upcase()

      [first | rest] ->
        last = List.last(rest)
        String.upcase(String.first(first) <> String.first(last))
    end
  end

  def initials(_), do: "?"

  @doc "Short name: first + last only (e.g., 'Fernando Hamasaki de Amorim' -> 'Fernando Amorim')"
  def short_name(name) when is_binary(name) do
    parts = String.split(name, ~r/\s+/)

    case parts do
      [single] -> single
      [first | rest] -> "#{first} #{List.last(rest)}"
    end
  end

  def short_name(_), do: ""

  @platform_labels %{
    twitter: "X",
    github: "GitHub",
    linkedin: "LinkedIn",
    mastodon: "Mastodon",
    bluesky: "Bluesky",
    instagram: "Instagram",
    youtube: "YouTube",
    website: "Website",
    meetup: "Meetup"
  }

  @talk_kind_labels %{
    keynote: "Keynote",
    talk: "Talk",
    workshop: "Workshop",
    panel: "Panel",
    lightning_talk: "Lightning Talk"
  }

  @doc "Human-readable label for a talk kind"
  def talk_kind_label(kind) when is_atom(kind),
    do:
      Map.get(
        @talk_kind_labels,
        kind,
        kind |> to_string() |> String.replace("_", " ") |> String.capitalize()
      )

  @role_labels %{
    organizer: "Organizer",
    mc: "MC",
    volunteer: "Volunteer",
    program_committee: "Program Committee"
  }

  @doc "Human-readable label for an event role"
  def role_label(role) when is_atom(role),
    do:
      Map.get(
        @role_labels,
        role,
        role |> to_string() |> String.replace("_", " ") |> String.capitalize()
      )

  @doc "Human-readable label for a social platform"
  def platform_label(platform) when is_atom(platform),
    do: Map.get(@platform_labels, platform, to_string(platform))

  def platform_label(platform) when is_binary(platform),
    do: Map.get(@platform_labels, String.to_existing_atom(platform), platform)

  @doc "Format city + country_code into a display label"
  def location_label(%{city: city, country_code: country_code}) do
    country_name =
      case country_code do
        nil -> nil
        code -> BeamLabCountries.get(code) |> then(&(&1 && &1.name))
      end

    [city, country_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  @doc "Return country options for select dropdowns"
  def country_options do
    BeamLabCountries.all()
    |> Enum.map(&{&1.name, &1.alpha2})
    |> Enum.sort_by(&elem(&1, 0))
  end

  @doc "Generate inline style for a speaker avatar gradient"
  def avatar_style(name), do: Colors.avatar_style(name)

  @doc "Generate inline style for an event card gradient"
  def card_style(event) do
    color = event.color || (event.event_series && event.event_series.color)
    Colors.card_style(event.name, color)
  end

  @doc "Generate inline style for a card background pattern"
  def card_pattern(name), do: Colors.card_pattern(name)

  @doc "Determine CFP status from an event's CFPs"
  def cfp_status(%{cfps: cfps}) when is_list(cfps) do
    today = Date.utc_today()

    Enum.find_value(cfps, fn cfp ->
      cond do
        cfp.close_date && Date.compare(today, cfp.close_date) == :gt -> :closed
        cfp.open_date && Date.compare(today, cfp.open_date) == :lt -> :upcoming
        true -> :open
      end
    end)
  end

  def cfp_status(_), do: nil

  @doc "Format event duration in days"
  def event_duration(%{start_date: start_date, end_date: end_date}) do
    days = Date.diff(end_date, start_date) + 1

    case days do
      1 -> "1 day"
      n -> "#{n} days"
    end
  end

  @doc "Format a date range"
  def date_range(%{start_date: start_date, end_date: end_date}) do
    start_month = Calendar.strftime(start_date, "%b")
    start_day = start_date.day
    end_day = end_date.day

    cond do
      start_date == end_date ->
        "#{start_month} #{start_day}"

      start_date.month == end_date.month ->
        "#{start_month} #{start_day} – #{end_day}"

      true ->
        end_month = Calendar.strftime(end_date, "%b")
        "#{start_month} #{start_day} – #{end_month} #{end_day}"
    end
  end

  @doc "Group events by year, preserving SQL ordering"
  def group_by_year(events) do
    events
    |> Enum.chunk_by(& &1.start_date.year)
    |> Enum.map(fn chunk -> {hd(chunk).start_date.year, chunk} end)
  end

  @doc "Series name or 'Independent'"
  def series_name(%{event_series: %{name: name}}), do: "#{name} Series"
  def series_name(_), do: "Independent"

  @doc "Speaker names from talk_speakers association"
  def speaker_names(%{talk_speakers: talk_speakers}) when is_list(talk_speakers) do
    talk_speakers
    |> Enum.sort_by(& &1.position)
    |> Enum.map_join(", ", & &1.profile.name)
  end

  def speaker_names(_), do: ""

  @doc "Check if a talk has any recordings"
  def has_recording?(%{recordings: recordings}) when is_list(recordings), do: recordings != []
  def has_recording?(_), do: false

  @doc "Get the best thumbnail URL for a talk's recording"
  def talk_thumbnail_url(%{recordings: [recording | _]}) do
    recording.thumbnail_url || youtube_thumbnail(recording)
  end

  def talk_thumbnail_url(_), do: nil

  defp youtube_thumbnail(%{provider: :youtube, external_id: id}) when is_binary(id) do
    "https://i.ytimg.com/vi/#{id}/sddefault.jpg"
  end

  defp youtube_thumbnail(_), do: nil

  @doc "Get the first recording URL for a talk"
  def recording_url(%{recordings: [recording | _]}), do: recording.url
  def recording_url(_), do: nil

  @doc "Generate the path for a talk show page"
  def talk_path(%{slug: slug, event: %{slug: event_slug}}), do: "/talks/#{event_slug}/#{slug}"
  def talk_path(%{slug: slug, event_id: _}), do: "/talks/#{slug}"

  @doc "CSS class for claim status badges"
  def claim_status_class(:pending), do: "bg-amber-500/15 text-amber-300"
  def claim_status_class(:approved), do: "bg-green-500/15 text-green-300"
  def claim_status_class(:rejected), do: "bg-red-500/15 text-red-300"
  def claim_status_class(:revoked), do: "bg-base-300 text-base-content/40"
  def claim_status_class(_), do: "bg-base-300 text-base-content/55"

  @doc "Format talk duration from minutes to MM:SS string"
  def format_duration(nil), do: nil

  def format_duration(minutes) when is_integer(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)

    if hours > 0 do
      "#{hours}:#{String.pad_leading(to_string(mins), 2, "0")}:00"
    else
      "#{mins}:00"
    end
  end

  @doc "Generate a Google Maps URL from a venue with coordinates"
  def google_maps_url(%{latitude: lat, longitude: lng})
      when not is_nil(lat) and not is_nil(lng) do
    "https://www.google.com/maps/place/#{lat},#{lng}"
  end

  @doc "Generate an Apple Maps URL from a venue with coordinates and name"
  def apple_maps_url(%{latitude: lat, longitude: lng, name: name})
      when not is_nil(lat) and not is_nil(lng) do
    encoded_name = URI.encode(name)
    "https://maps.apple.com/?ll=#{lat},#{lng}&q=#{encoded_name}"
  end

  @doc "Generate an OpenStreetMap URL from a venue with coordinates"
  def openstreetmap_url(%{latitude: lat, longitude: lng})
      when not is_nil(lat) and not is_nil(lng) do
    "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{lng}&zoom=16"
  end

  @doc "Generate an OpenStreetMap embed URL with bounding box from a venue with coordinates"
  def openstreetmap_embed_url(%{latitude: lat, longitude: lng})
      when not is_nil(lat) and not is_nil(lng) do
    lat_f = Decimal.to_float(lat)
    lng_f = Decimal.to_float(lng)
    bbox = "#{lng_f - 0.01},#{lat_f - 0.005},#{lng_f + 0.01},#{lat_f + 0.005}"

    "https://www.openstreetmap.org/export/embed.html?bbox=#{bbox}&layer=mapnik&marker=#{lat},#{lng}"
  end

  @doc "Returns true if the given map has non-nil latitude and longitude"
  def has_coordinates?(%{latitude: lat, longitude: lng})
      when not is_nil(lat) and not is_nil(lng),
      do: true

  def has_coordinates?(_), do: false

  @doc "Format label for workshop format, falling back to event format"
  def workshop_format_label(%{format: nil, event: event}),
    do: event.format |> to_string() |> String.replace("_", " ")

  def workshop_format_label(%{format: format}),
    do: format |> to_string() |> String.replace("_", " ")

  @doc "Render Markdown text as safe HTML"
  def render_markdown(nil), do: ""
  def render_markdown(""), do: ""

  def render_markdown(text) do
    text
    |> MDEx.to_html!(extension: [table: true, strikethrough: true, autolink: true])
    |> Phoenix.HTML.raw()
  end
end
