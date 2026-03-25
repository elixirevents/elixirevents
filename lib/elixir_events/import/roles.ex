defmodule ElixirEvents.Import.Roles do
  @moduledoc false

  require Logger

  alias ElixirEvents.Events

  @role_mapping %{
    "Organizer" => :organizer,
    "MC" => :mc,
    "Volunteer" => :volunteer,
    "Program Committee" => :program_committee
  }

  def run(event_dir, event) do
    path = Path.join(event_dir, "roles.yml")

    if File.exists?(path) do
      data = YamlElixir.read_from_file!(path)
      Logger.info("Importing roles for #{event.name}...")

      roles_attrs =
        Enum.flat_map(data, fn group ->
          role = Map.get(@role_mapping, group["name"], :volunteer)

          Enum.map(group["members"] || [], fn member ->
            %{name: member["name"], role: role, position: member["position"]}
          end)
        end)

      Events.replace_event_roles(event.id, roles_attrs)
      :ok
    else
      {:ok, :skipped}
    end
  end
end
