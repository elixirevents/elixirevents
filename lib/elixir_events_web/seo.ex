defmodule ElixirEventsWeb.SEO do
  @moduledoc """
  JSON-LD structured data and SEO helpers for ElixirEvents.
  """

  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]

  alias ElixirEvents.Events.Event
  alias ElixirEvents.Talks.Talk
  alias ElixirEvents.Venues.Venue

  @base_url "https://elixirevents.org"

  attr :data, :any, required: true

  def jsonld_script(assigns) do
    ~H"""
    <script type="application/ld+json">
      <%= raw(JSON.encode!(@data)) %>
    </script>
    """
  end

  def base_url, do: @base_url

  # ── JSON-LD builders ──────────────────────────────────────────────

  @doc "Builds JSON-LD for an Event show page."
  def event_jsonld(%Event{} = event) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Event",
      "name" => event.name,
      "startDate" => to_iso(event.start_date),
      "endDate" => to_iso(event.end_date),
      "eventStatus" => event_status(event.status),
      "eventAttendanceMode" => attendance_mode(event.format),
      "url" => "#{@base_url}/events/#{event.slug}",
      "description" => event.description
    }
    |> maybe_put("location", event_location(event))
    |> maybe_put("image", event.banner_url)
    |> maybe_put("organizer", event_organizer(event))
    |> maybe_put("offers", event_offers(event))
    |> compact()
  end

  @doc "Builds JSON-LD ItemList for the events index / homepage."
  def event_list_jsonld(events) do
    items =
      events
      |> Enum.with_index(1)
      |> Enum.map(fn {event, position} ->
        %{
          "@type" => "ListItem",
          "position" => position,
          "url" => "#{@base_url}/events/#{event.slug}",
          "name" => event.name
        }
      end)

    %{
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "itemListElement" => items
    }
  end

  @doc "Builds JSON-LD for a Talk show page."
  def talk_jsonld(%Talk{} = talk) do
    base = %{
      "@context" => "https://schema.org",
      "@type" => "CreativeWork",
      "name" => talk.title,
      "description" => talk.abstract,
      "inLanguage" => talk.language,
      "url" => "#{@base_url}/talks/#{talk.event.slug}/#{talk.slug}"
    }

    recording = List.first(talk.recordings || [])

    if recording do
      base
      |> Map.merge(%{
        "@type" => "VideoObject",
        "contentUrl" => recording.url,
        "thumbnailUrl" => recording.thumbnail_url,
        "uploadDate" => to_iso(recording.published_at),
        "duration" => iso_duration(recording.duration)
      })
      |> compact()
    else
      base |> compact()
    end
  end

  @doc "Builds JSON-LD for the website (used on homepage)."
  def website_jsonld do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "ElixirEvents",
      "url" => @base_url,
      "description" =>
        "The home for Elixir & BEAM events. Conferences, meetups, and talks across the Elixir ecosystem."
    }
  end

  # ── Helpers ────────────────────────────────────────────────────────

  defp event_location(%Event{venue: %Venue{} = venue}) do
    %{
      "@type" => "Place",
      "name" => venue.name,
      "address" =>
        %{
          "@type" => "PostalAddress",
          "streetAddress" => venue.street,
          "addressLocality" => venue.city,
          "addressRegion" => venue.region,
          "postalCode" => venue.postal_code,
          "addressCountry" => venue.country_code
        }
        |> compact()
    }
    |> maybe_put_geo(venue)
  end

  defp event_location(%Event{location: location}) when is_binary(location) and location != "" do
    %{"@type" => "Place", "name" => location}
  end

  defp event_location(_), do: nil

  defp maybe_put_geo(place, %Venue{latitude: lat, longitude: lng})
       when not is_nil(lat) and not is_nil(lng) do
    Map.put(place, "geo", %{
      "@type" => "GeoCoordinates",
      "latitude" => Decimal.to_float(lat),
      "longitude" => Decimal.to_float(lng)
    })
  end

  defp maybe_put_geo(place, _), do: place

  defp event_organizer(%Event{event_series: %{name: name, website: website}})
       when is_binary(name) do
    %{"@type" => "Organization", "name" => name}
    |> maybe_put("url", website)
  end

  defp event_organizer(_), do: nil

  defp event_offers(%Event{tickets_url: url}) when is_binary(url) and url != "" do
    %{"@type" => "Offer", "url" => url}
  end

  defp event_offers(_), do: nil

  defp event_status(:announced), do: "https://schema.org/EventScheduled"
  defp event_status(:confirmed), do: "https://schema.org/EventScheduled"
  defp event_status(:ongoing), do: "https://schema.org/EventScheduled"
  defp event_status(:cancelled), do: "https://schema.org/EventCancelled"
  defp event_status(:completed), do: "https://schema.org/EventScheduled"
  defp event_status(_), do: "https://schema.org/EventScheduled"

  defp attendance_mode(:online), do: "https://schema.org/OnlineEventAttendanceMode"
  defp attendance_mode(:hybrid), do: "https://schema.org/MixedEventAttendanceMode"
  defp attendance_mode(_), do: "https://schema.org/OfflineEventAttendanceMode"

  defp to_iso(%Date{} = date), do: Date.to_iso8601(date)
  defp to_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp to_iso(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp to_iso(nil), do: nil
  defp to_iso(other), do: to_string(other)

  defp iso_duration(nil), do: nil

  defp iso_duration(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    parts =
      [{"H", hours}, {"M", minutes}, {"S", secs}]
      |> Enum.reject(fn {_, v} -> v == 0 end)
      |> Enum.map(fn {suffix, v} -> "#{v}#{suffix}" end)

    "PT#{Enum.join(parts)}"
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp compact(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
    |> Enum.map(fn {k, v} -> {k, compact(v)} end)
    |> Map.new()
  end

  defp compact(value), do: value
end
