defmodule ElixirEvents.Import.Profiles do
  @moduledoc false

  alias ElixirEvents.{Import, Profiles}

  def run(data_dir) do
    path = Path.join(data_dir, "speakers.yml")

    if File.exists?(path) do
      path
      |> YamlElixir.read_from_file!()
      |> Import.each_with_progress("profiles", &import_profile/1)

      :ok
    else
      {:ok, :skipped}
    end
  end

  defp import_profile(data) do
    attrs = %{
      name: data["name"],
      handle: handleize(data["slug"]),
      headline: data["headline"],
      bio: data["bio"],
      city: data["city"],
      country_code: data["country_code"],
      website: data["website"],
      avatar_url: data["avatar_url"],
      is_speaker: true,
      social_links: parse_social_links(data["social_links"])
    }

    Profiles.upsert_profile(attrs)
  end

  defp handleize(slug) when is_binary(slug) do
    slug |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "")
  end

  defp handleize(nil), do: nil

  def parse_social_links(nil), do: []

  def parse_social_links(links) do
    Enum.map(links, fn link ->
      %{
        platform: String.to_atom(link["platform"]),
        url: link["url"],
        label: link["label"]
      }
    end)
  end
end
