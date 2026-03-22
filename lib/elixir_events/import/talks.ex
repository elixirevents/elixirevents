defmodule ElixirEvents.Import.Talks do
  @moduledoc false

  require Logger

  alias ElixirEvents.{Profiles, Talks, Topics}

  def run(event_dir, event) do
    path = Path.join(event_dir, "talks.yml")

    if File.exists?(path) do
      path
      |> YamlElixir.read_from_file!()
      |> Enum.each(&import_talk(&1, event))

      :ok
    else
      {:ok, :skipped}
    end
  end

  defp import_talk(data, event) do
    attrs = %{
      event_id: event.id,
      title: data["title"],
      slug: data["slug"],
      kind: String.to_atom(data["kind"]),
      level: parse_atom(data["level"]),
      language: data["language"] || "en",
      abstract: data["abstract"] || data["description"],
      duration: data["duration"]
    }

    case Talks.upsert_talk(attrs) do
      {:ok, talk} ->
        import_talk_speakers(talk, data["speakers"])
        import_talk_topics(talk, data["topics"])
        import_recordings(talk, data["recordings"])
        import_talk_links(talk, data["links"])

      {:error, changeset} ->
        Logger.warning("Failed to import talk '#{data["title"]}': #{inspect(changeset.errors)}")
    end
  end

  defp import_talk_speakers(_talk, nil), do: :ok

  defp import_talk_speakers(talk, speaker_slugs) do
    speakers_attrs =
      speaker_slugs
      |> Enum.map(&to_string/1)
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {slug, position} ->
        handle = slug |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "")

        case Profiles.get_profile_by_handle(handle) do
          nil ->
            Logger.warning("Profile not found: #{slug}")
            []

          profile ->
            [%{profile_id: profile.id, role: :speaker, position: position}]
        end
      end)

    Talks.replace_talk_speakers(talk.id, speakers_attrs)
  end

  # Note: Topic tags are additive (on_conflict: :nothing). If a topic is removed
  # from YAML, the old tag persists in DB. This is intentional — tags added via
  # UI are preserved. To prune stale tags, a separate cleanup task would be needed.
  defp import_talk_topics(_talk, nil), do: :ok

  defp import_talk_topics(talk, topic_slugs) do
    Enum.each(topic_slugs, fn slug ->
      case Topics.get_topic_by_slug(slug) do
        nil -> Logger.warning("Topic not found: #{slug}")
        topic -> Topics.tag_talk(talk.id, topic.id)
      end
    end)
  end

  defp import_recordings(_talk, nil), do: :ok

  defp import_recordings(talk, recordings) do
    recs_attrs =
      Enum.map(recordings, fn rec ->
        %{
          provider: String.to_atom(rec["provider"]),
          external_id: if(rec["external_id"], do: to_string(rec["external_id"])),
          url: rec["url"],
          thumbnail_url: rec["thumbnail_url"]
        }
      end)

    Talks.replace_recordings(talk.id, recs_attrs)
  end

  defp import_talk_links(_talk, nil), do: :ok

  defp import_talk_links(talk, links) do
    links_attrs =
      Enum.map(links, fn link ->
        %{
          kind: String.to_atom(link["kind"]),
          url: link["url"],
          label: link["label"]
        }
      end)

    Talks.replace_talk_links(talk.id, links_attrs)
  end

  defp parse_atom(nil), do: nil
  defp parse_atom(val) when is_atom(val), do: val
  defp parse_atom(val) when is_binary(val), do: String.to_atom(val)
end
