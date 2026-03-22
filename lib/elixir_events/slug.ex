defmodule ElixirEvents.Slug do
  @moduledoc false

  import Ecto.Changeset

  @slug_pattern ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/
  @max_length 60

  def slugify(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9-]+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.replace(~r/^-+|-+$/, "")
  end

  def slugify(_), do: nil

  @doc """
  Returns true if the string is a valid slug.
  """
  def valid?(slug) when is_binary(slug), do: Regex.match?(@slug_pattern, slug)
  def valid?(_), do: false

  @doc """
  Sanitizes a string into a valid slug, fixing common issues:
  underscores, trailing hyphens, special characters, and excessive length.

  Unlike `slugify/1`, this is meant for cleaning up existing slugs that
  are close to valid but have minor issues.
  """
  def sanitize(slug) when is_binary(slug) do
    slug
    |> String.downcase()
    |> String.replace("_", "-")
    |> String.replace(~r/[^a-z0-9-]/, "")
    |> String.replace(~r/-+/, "-")
    |> String.replace(~r/^-+|-+$/, "")
    |> truncate()
  end

  def sanitize(_), do: nil

  defp truncate(slug) when byte_size(slug) > @max_length do
    slug |> String.slice(0, @max_length) |> String.replace(~r/-+$/, "")
  end

  defp truncate(slug), do: slug

  @doc """
  Generates a slug from `source_field` if `:slug` is not already set in the changeset.
  """
  def maybe_generate_slug(changeset, source_field \\ :name) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, source_field) || get_field(changeset, source_field) do
          nil -> changeset
          value -> put_change(changeset, :slug, slugify(value))
        end

      _slug ->
        changeset
    end
  end

  def validate_slug_format(changeset, field_name \\ :slug) do
    validate_format(changeset, field_name, @slug_pattern,
      message: "is invalid. Only lowercase letters, numbers, and connecting hyphens are allowed."
    )
  end
end
