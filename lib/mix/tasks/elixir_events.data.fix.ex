defmodule Mix.Tasks.ElixirEvents.Data.Fix do
  use Mix.Task

  alias ElixirEvents.Slug

  @shortdoc "Auto-fix common YAML data issues"

  @moduledoc """
  Fixes known safe patterns in YAML data files:

  - Sanitizes slugs (underscores → hyphens, trailing hyphens, special chars, length)
  - Fixes nested double quotes (switches to single-quoted YAML)
  - Deduplicates slugs within the same talks.yml file

  ## Usage

      mix elixir_events.data.fix
      mix elixir_events.data.fix --data-dir path/to/data
      mix elixir_events.data.fix --dry-run
  """

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [data_dir: :string, dry_run: :boolean])
    data_dir = opts[:data_dir] || Path.join(File.cwd!(), "priv/data")
    dry_run = opts[:dry_run] || false

    fixes = []

    fixes = fixes ++ fix_slugs_in_files(data_dir, dry_run)
    fixes = fixes ++ fix_nested_quotes(data_dir, dry_run)
    fixes = fixes ++ fix_duplicate_talk_slugs(data_dir, dry_run)

    case fixes do
      [] ->
        Mix.shell().info("No fixes needed.")

      fixes ->
        if dry_run do
          Mix.shell().info("Would apply #{length(fixes)} fix(es):")
        else
          Mix.shell().info("Applied #{length(fixes)} fix(es):")
        end

        Enum.each(fixes, fn fix ->
          Mix.shell().info("  #{fix}")
        end)
    end
  end

  defp fix_slugs_in_files(data_dir, dry_run) do
    Path.wildcard(Path.join(data_dir, "**/*.yml"))
    |> Enum.flat_map(&fix_slugs_in_file(&1, dry_run))
  end

  defp fix_slugs_in_file(path, dry_run) do
    content = File.read!(path)

    {new_content, fixes} =
      Regex.scan(~r/slug:\s*"([^"]+)"/, content, return: :index)
      |> Enum.reduce({content, []}, fn [{_full_start, _full_len}, {val_start, val_len}],
                                       {cont, fixes} ->
        slug = String.slice(cont, val_start, val_len)
        sanitized = Slug.sanitize(slug)

        if sanitized != slug and sanitized != "" do
          relative = Path.relative_to_cwd(path)
          fix = "#{relative}: slug '#{slug}' → '#{sanitized}'"

          new_cont =
            String.replace(cont, ~s(slug: "#{slug}"), ~s(slug: "#{sanitized}"), global: false)

          {new_cont, [fix | fixes]}
        else
          {cont, fixes}
        end
      end)

    if not dry_run and fixes != [] do
      File.write!(path, new_content)
    end

    Enum.reverse(fixes)
  end

  defp fix_nested_quotes(data_dir, dry_run) do
    Path.wildcard(Path.join(data_dir, "**/talks.yml"))
    |> Enum.flat_map(&fix_quotes_in_file(&1, dry_run))
  end

  defp fix_quotes_in_file(path, dry_run) do
    content = File.read!(path)
    lines = String.split(content, "\n")

    {fixed_lines, fixes} =
      Enum.reduce(lines, {[], []}, fn line, {acc_lines, acc_fixes} ->
        case Regex.run(~r/^(\s*-?\s*(?:title|abstract|name|bio|headline):\s*)"(.+)"(\s*)$/, line) do
          [_, prefix, value, suffix] when byte_size(value) > 0 ->
            if String.contains?(value, "\"") do
              escaped = String.replace(value, "'", "''")
              fixed = "#{prefix}'#{escaped}'#{suffix}"
              relative = Path.relative_to_cwd(path)
              fix = "#{relative}: fixed nested quotes in value"
              {[fixed | acc_lines], [fix | acc_fixes]}
            else
              {[line | acc_lines], acc_fixes}
            end

          _ ->
            {[line | acc_lines], acc_fixes}
        end
      end)

    if not dry_run and fixes != [] do
      fixed_lines |> Enum.reverse() |> Enum.join("\n") |> then(&File.write!(path, &1))
    end

    Enum.reverse(fixes) |> Enum.uniq()
  end

  defp fix_duplicate_talk_slugs(data_dir, dry_run) do
    Path.wildcard(Path.join(data_dir, "**/talks.yml"))
    |> Enum.flat_map(&fix_dupes_in_file(&1, dry_run))
  end

  defp fix_dupes_in_file(path, dry_run) do
    content = File.read!(path)

    slugs = Regex.scan(~r/slug:\s*"([^"]+)"/, content) |> Enum.map(&List.last/1)
    dupes = slugs |> Enum.frequencies() |> Enum.filter(fn {_, c} -> c > 1 end) |> Map.new()

    if map_size(dupes) == 0 do
      []
    else
      counters = Map.new(dupes, fn {slug, _} -> {slug, 0} end)

      {new_content, _counters} =
        Regex.scan(~r/slug:\s*"([^"]+)"/, content, return: :index)
        |> Enum.reduce({content, counters}, fn match, acc ->
          dedup_slug_match(match, content, acc)
        end)

      relative = Path.relative_to_cwd(path)

      fixes =
        Enum.map(dupes, fn {slug, count} ->
          "#{relative}: deduplicated slug '#{slug}' (#{count} occurrences)"
        end)

      if not dry_run do
        File.write!(path, new_content)
      end

      fixes
    end
  end

  defp dedup_slug_match([{_full_start, _full_len}, {val_start, val_len}], content, {cont, ctrs}) do
    slug = String.slice(content, val_start, val_len)

    case Map.fetch(ctrs, slug) do
      {:ok, prev_count} ->
        count = prev_count + 1
        new_ctrs = Map.put(ctrs, slug, count)

        if count > 1 do
          new_slug = "#{slug}-#{count}"

          new_cont =
            String.replace(cont, ~s(slug: "#{slug}"), ~s(slug: "#{new_slug}"), global: false)

          {new_cont, new_ctrs}
        else
          {cont, new_ctrs}
        end

      :error ->
        {cont, ctrs}
    end
  end
end
