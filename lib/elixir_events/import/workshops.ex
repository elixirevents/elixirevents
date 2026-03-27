defmodule ElixirEvents.Import.Workshops do
  @moduledoc false

  require Logger

  alias ElixirEvents.{Profiles, Topics, Venues, Workshops}

  def run(event_dir, event) do
    path = Path.join(event_dir, "workshops.yml")

    if File.exists?(path) do
      workshops_data = YamlElixir.read_from_file!(path)
      Logger.info("Importing #{length(workshops_data)} workshops for #{event.name}...")

      Enum.each(workshops_data, &import_workshop(&1, event))

      yaml_slugs = Enum.map(workshops_data, & &1["slug"]) |> Enum.reject(&is_nil/1)
      Workshops.delete_orphaned_workshops(event.id, yaml_slugs)

      Logger.info("Workshops import complete for #{event.name}")
      :ok
    else
      {:ok, :skipped}
    end
  end

  defp import_workshop(data, event) do
    venue_id = resolve_venue(data["venue_slug"])

    agenda =
      (data["agenda"] || [])
      |> Enum.map(fn day ->
        %{
          day_number: day["day"],
          title: day["title"],
          start_time: parse_time(day["start_time"]),
          end_time: parse_time(day["end_time"]),
          items: day["items"] || []
        }
      end)

    attrs = %{
      event_id: event.id,
      venue_id: venue_id,
      title: data["title"],
      slug: data["slug"],
      description: data["description"],
      format: parse_atom(data["format"]),
      experience_level: data["experience_level"],
      target_audience: data["target_audience"],
      language: data["language"] || "en",
      start_date: parse_date(data["start_date"]),
      end_date: parse_date(data["end_date"]),
      booking_url: data["booking_url"],
      attendees_only: data["attendees_only"] || false,
      agenda: agenda
    }

    case Workshops.upsert_workshop(attrs) do
      {:ok, workshop} ->
        import_trainers(workshop, data["trainers"])
        import_topics(workshop, data["topics"])

      {:error, changeset} ->
        Logger.warning(
          "Failed to import workshop '#{data["title"]}': #{inspect(changeset.errors)}"
        )
    end
  end

  defp import_trainers(_workshop, nil), do: :ok

  defp import_trainers(workshop, trainer_slugs) do
    trainers_attrs =
      trainer_slugs
      |> Enum.map(&to_string/1)
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {slug, position} ->
        handle = slug |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "")

        case Profiles.get_profile_by_handle(handle) do
          nil ->
            Logger.warning("Profile not found for trainer: #{slug}")
            []

          profile ->
            [%{profile_id: profile.id, position: position}]
        end
      end)

    Workshops.replace_workshop_trainers(workshop.id, trainers_attrs)
  end

  defp import_topics(_workshop, nil), do: :ok

  defp import_topics(workshop, topic_slugs) do
    Enum.each(topic_slugs, fn slug ->
      case Topics.get_topic_by_slug(slug) do
        nil -> Logger.warning("Topic not found: #{slug}")
        topic -> Topics.tag_workshop(workshop.id, topic.id)
      end
    end)
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

  defp parse_time(nil), do: nil

  defp parse_time(str) when is_binary(str) do
    case Time.from_iso8601(str <> ":00") do
      {:ok, time} -> time
      _ -> nil
    end
  end

  defp parse_atom(nil), do: nil
  defp parse_atom(val) when is_atom(val), do: val
  defp parse_atom(val) when is_binary(val), do: String.to_atom(val)
end
