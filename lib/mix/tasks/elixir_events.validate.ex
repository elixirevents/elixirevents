defmodule Mix.Tasks.ElixirEvents.Validate do
  use Mix.Task

  @shortdoc "Validate YAML data files against expected schemas"

  @moduledoc """
  Validates all YAML data files in priv/data/ without touching the database.

  Checks YAML parsability, required fields, enum values, slug format,
  date format, duplicate slugs, and cross-file references.

  ## Usage

      mix elixir_events.validate
      mix elixir_events.validate --data-dir path/to/data

  Exits with code 1 if validation errors are found. Outputs errors in
  a format suitable for CI annotations.
  """

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [data_dir: :string])
    data_dir = opts[:data_dir] || Path.join(File.cwd!(), "priv/data")

    Mix.shell().info("Validating data in #{data_dir}...")

    case ElixirEvents.DataValidator.validate(data_dir) do
      {:ok, stats} ->
        Mix.shell().info("Validation passed. #{stats.series} series validated.")

      {:error, errors} ->
        Mix.shell().error("Validation failed with #{length(errors)} error(s):\n")

        Enum.each(errors, fn
          %{path: path, message: msg, location: loc} ->
            relative = Path.relative_to_cwd(path)
            prefix = if loc, do: "#{relative} (#{loc})", else: relative

            # GitHub Actions annotation format
            if System.get_env("GITHUB_ACTIONS") do
              Mix.shell().error("::error file=#{relative}::#{msg}")
            else
              Mix.shell().error("  #{prefix}: #{msg}")
            end

          %{path: path, message: msg} ->
            relative = Path.relative_to_cwd(path)

            if System.get_env("GITHUB_ACTIONS") do
              Mix.shell().error("::error file=#{relative}::#{msg}")
            else
              Mix.shell().error("  #{relative}: #{msg}")
            end
        end)

        Mix.raise("Validation failed with #{length(errors)} error(s)")
    end
  end
end
