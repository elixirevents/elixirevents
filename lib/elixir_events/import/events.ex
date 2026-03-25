defmodule ElixirEvents.Import.Events do
  @moduledoc false

  require Logger

  alias ElixirEvents.{Events, Venues}
  alias ElixirEvents.Import.Profiles, as: ProfileImport

  def run(event_dir, series) do
    path = Path.join(event_dir, "event.yml")

    if File.exists?(path) do
      data = YamlElixir.read_from_file!(path)
      Logger.info("Importing event: #{data["name"]}...")

      venue_id = resolve_venue(data["venue_slug"])

      attrs = %{
        name: data["name"],
        slug: data["slug"],
        event_series_id: series.id,
        venue_id: venue_id,
        kind: String.to_atom(data["kind"]),
        status: String.to_atom(data["status"]),
        format: String.to_atom(data["format"]),
        start_date: parse_date(data["start_date"]),
        end_date: parse_date(data["end_date"]),
        timezone: data["timezone"],
        language: data["language"] || "en",
        location: data["location"],
        website: data["website"],
        tickets_url: data["tickets_url"],
        banner_url: data["banner_url"],
        description: data["description"],
        social_links: ProfileImport.parse_social_links(data["social_links"])
      }

      Events.upsert_event(attrs)
    else
      {:error, {:events, :file_not_found}}
    end
  end

  defp resolve_venue(nil), do: nil

  defp resolve_venue(slug) do
    case Venues.get_venue_by_slug(slug) do
      nil ->
        Logger.warning("Venue not found: #{slug}")
        nil

      venue ->
        venue.id
    end
  end

  defp parse_date(%Date{} = date), do: date
  defp parse_date(str) when is_binary(str), do: Date.from_iso8601!(str)
  defp parse_date(nil), do: nil
end
