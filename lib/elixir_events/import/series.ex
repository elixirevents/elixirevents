defmodule ElixirEvents.Import.Series do
  @moduledoc false

  alias ElixirEvents.Events
  alias ElixirEvents.Import.Profiles, as: ProfileImport

  def run(series_dir) do
    path = Path.join(series_dir, "series.yml")

    if File.exists?(path) do
      data = YamlElixir.read_from_file!(path)

      attrs = %{
        name: data["name"],
        slug: data["slug"],
        kind: String.to_atom(data["kind"]),
        frequency: parse_atom(data["frequency"]),
        language: data["language"],
        website: data["website"],
        ended: data["ended"] || false,
        listed: if(data["listed"] == false, do: false, else: true),
        description: data["description"],
        social_links: ProfileImport.parse_social_links(data["social_links"])
      }

      Events.upsert_event_series(attrs)
    else
      {:ok, :skipped}
    end
  end

  defp parse_atom(nil), do: nil
  defp parse_atom(val) when is_atom(val), do: val
  defp parse_atom(val) when is_binary(val), do: String.to_atom(val)
end
