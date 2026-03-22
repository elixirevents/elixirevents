defmodule ElixirEvents.Import.Topics do
  @moduledoc false

  alias ElixirEvents.Topics

  def run(data_dir) do
    path = Path.join(data_dir, "topics.yml")

    if File.exists?(path) do
      path
      |> YamlElixir.read_from_file!()
      |> Enum.each(&import_topic/1)

      :ok
    else
      {:ok, :skipped}
    end
  end

  defp import_topic(data) do
    attrs = %{
      name: data["name"],
      slug: data["slug"],
      description: data["description"]
    }

    Topics.upsert_topic(attrs)
  end
end
