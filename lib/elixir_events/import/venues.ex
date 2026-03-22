defmodule ElixirEvents.Import.Venues do
  @moduledoc false

  alias ElixirEvents.Venues

  def run(data_dir) do
    path = Path.join(data_dir, "venues.yml")

    if File.exists?(path) do
      path
      |> YamlElixir.read_from_file!()
      |> Enum.each(&import_venue/1)

      :ok
    else
      {:ok, :skipped}
    end
  end

  defp import_venue(data) do
    attrs = %{
      name: data["name"],
      slug: data["slug"],
      street: data["street"],
      city: data["city"],
      region: data["region"],
      country: data["country"],
      country_code: data["country_code"],
      postal_code: data["postal_code"],
      latitude: data["latitude"],
      longitude: data["longitude"],
      website: data["website"]
    }

    Venues.upsert_venue(attrs)
  end
end
