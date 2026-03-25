defmodule ElixirEvents.Import.Schedule do
  @moduledoc false

  require Logger

  alias ElixirEvents.{Program, Talks}

  def run(event_dir, event) do
    path = Path.join(event_dir, "schedule.yml")

    if File.exists?(path) do
      data = YamlElixir.read_from_file!(path)
      Logger.info("Importing schedule for #{event.name}...")
      import_schedule(data, event)
      Logger.info("Schedule import complete for #{event.name}")
      :ok
    else
      {:ok, :skipped}
    end
  end

  defp import_schedule(data, event) do
    # Build tracks
    tracks_data = data["tracks"] || []

    tracks_attrs =
      Enum.map(tracks_data, fn t ->
        %{name: t["name"], color: t["color"], position: t["position"]}
      end)

    # Build days and time_slots
    days_data = data["days"] || []

    time_slots_by_date =
      Map.new(days_data, fn day ->
        slots =
          Enum.map(day["time_slots"] || [], fn slot ->
            %{start_time: parse_time(slot["start_time"]), end_time: parse_time(slot["end_time"])}
          end)

        {parse_date(day["date"]), slots}
      end)

    days_attrs =
      Enum.map(days_data, fn day ->
        %{date: parse_date(day["date"]), name: day["name"], position: day["position"]}
      end)

    # Use replace_schedule — everything in one transaction
    {:ok, result} =
      Program.replace_schedule(event.id, %{
        tracks: tracks_attrs,
        days: days_attrs,
        time_slots: time_slots_by_date,
        sessions: []
      })

    # Create sessions after schedule structure exists (tracks/slots now have IDs)
    track_map = Map.new(result.tracks, fn t -> {t.name, t} end)

    Enum.each(days_data, fn day ->
      day_record = Enum.find(result.days, fn d -> d.date == parse_date(day["date"]) end)

      Enum.each(day["time_slots"] || [], fn slot_data ->
        slot_time = parse_time(slot_data["start_time"])
        slot_record = Enum.find(day_record.time_slots, fn s -> s.start_time == slot_time end)

        Enum.each(slot_data["sessions"] || [], fn session_data ->
          import_session(session_data, event, slot_record, track_map)
        end)
      end)
    end)
  end

  defp import_session(data, event, slot, track_map) do
    talk = resolve_talk(data["talk_slug"], event.id)
    track = track_map[data["track"]]
    title = data["title"] || (talk && talk.title) || "Untitled"

    Program.create_session(%{
      event_id: event.id,
      talk_id: talk && talk.id,
      time_slot_id: slot && slot.id,
      track_id: track && track.id,
      title: title,
      kind: String.to_atom(data["kind"])
    })
  end

  defp resolve_talk(nil, _event_id), do: nil

  defp resolve_talk(slug, event_id) do
    case Talks.get_talk_by_slug(event_id, slug) do
      nil ->
        Logger.warning("Talk not found: #{slug}")
        nil

      talk ->
        talk
    end
  end

  defp parse_time(str) when is_binary(str) do
    [h, m] = String.split(str, ":")
    Time.new!(String.to_integer(h), String.to_integer(m), 0)
  end

  defp parse_date(%Date{} = date), do: date
  defp parse_date(str) when is_binary(str), do: Date.from_iso8601!(str)
end
