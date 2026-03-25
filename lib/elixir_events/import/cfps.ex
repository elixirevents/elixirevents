defmodule ElixirEvents.Import.CFPs do
  @moduledoc false

  require Logger

  alias ElixirEvents.Submissions

  def run(event_dir, event) do
    path = Path.join(event_dir, "cfp.yml")

    if File.exists?(path) do
      data = YamlElixir.read_from_file!(path)
      Logger.info("Importing #{length(data)} CFPs for #{event.name}...")

      cfps_attrs =
        Enum.map(data, fn cfp ->
          %{
            name: cfp["name"],
            url: cfp["url"],
            description: cfp["description"],
            open_date: parse_date(cfp["open_date"]),
            close_date: parse_date(cfp["close_date"])
          }
        end)

      Submissions.replace_cfps(event.id, cfps_attrs)
      :ok
    else
      {:ok, :skipped}
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(%Date{} = date), do: date
  defp parse_date(str) when is_binary(str), do: Date.from_iso8601!(str)
end
