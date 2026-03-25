defmodule ElixirEvents.Import.Organizations do
  @moduledoc false

  alias ElixirEvents.{Import, Organizations}

  def run(data_dir) do
    path = Path.join(data_dir, "organizations.yml")

    if File.exists?(path) do
      path
      |> YamlElixir.read_from_file!()
      |> Import.each_with_progress("organizations", &import_organization/1)

      :ok
    else
      {:ok, :skipped}
    end
  end

  defp import_organization(data) do
    attrs = %{
      name: data["name"],
      slug: data["slug"],
      description: data["description"],
      website: data["website"],
      logo_url: data["logo_url"]
    }

    Organizations.upsert_organization(attrs)
  end
end
