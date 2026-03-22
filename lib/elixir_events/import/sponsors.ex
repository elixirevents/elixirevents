defmodule ElixirEvents.Import.Sponsors do
  @moduledoc false

  require Logger

  alias ElixirEvents.{Organizations, Sponsorship}

  def run(event_dir, event) do
    path = Path.join(event_dir, "sponsors.yml")

    if File.exists?(path) do
      data = YamlElixir.read_from_file!(path)

      tiers_attrs =
        Enum.map(data, fn tier ->
          sponsors = Enum.flat_map(tier["sponsors"] || [], &resolve_sponsor/1)
          %{name: tier["name"], level: tier["level"], sponsors: sponsors}
        end)

      Sponsorship.replace_sponsor_tiers(event.id, tiers_attrs)
      :ok
    else
      {:ok, :skipped}
    end
  end

  defp resolve_sponsor(s) do
    case Organizations.get_organization_by_slug(s["slug"]) do
      nil ->
        Logger.warning("Organization not found: #{s["slug"]}")
        []

      org ->
        badge = if s["badge"], do: String.to_atom(s["badge"]), else: nil
        [%{organization_id: org.id, badge: badge}]
    end
  end
end
