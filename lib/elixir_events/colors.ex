defmodule ElixirEvents.Colors do
  @moduledoc """
  Deterministic color generation from strings.
  Produces consistent oklch-based gradients for avatars, cards, and badges.
  The same string always produces the same color.
  """

  @doc """
  Generate a deterministic hue (0-360) from a string.
  Uses erlang's phash2 for uniform distribution.
  """
  def hue_from_string(string) when is_binary(string) do
    :erlang.phash2(string, 360)
  end

  @doc """
  Generate inline CSS style for a speaker avatar gradient.
  Returns a background gradient with text color that contrasts well.
  """
  def avatar_style(name) when is_binary(name) do
    hue = hue_from_string(name)
    hue2 = rem(hue + 20, 360)

    "background: linear-gradient(135deg, oklch(85% 0.1 #{hue}), oklch(78% 0.14 #{hue2})); color: oklch(35% 0.12 #{hue});"
  end

  @doc """
  Generate inline CSS style for an event card gradient.
  Darker gradient suitable for white text overlay.
  Uses event color if available, otherwise generates from name.
  """
  def card_style(name, color \\ nil)

  def card_style(_name, color) when is_binary(color) and color != "" do
    "background: #{color};"
  end

  def card_style(name, _color) when is_binary(name) do
    hue = hue_from_string(name)
    hue2 = rem(hue + 40, 360)

    "background: linear-gradient(135deg, oklch(38% 0.16 #{hue}), oklch(50% 0.19 #{hue2}));"
  end

  @doc """
  Generate a subtle background pattern style for event cards.
  Deterministic pattern selection based on name.
  """
  def card_pattern(name) when is_binary(name) do
    pattern_index = rem(:erlang.phash2(name, 4), 4)

    case pattern_index do
      0 ->
        "background-image: radial-gradient(circle at 2px 2px, white 1px, transparent 0); background-size: 20px 20px;"

      1 ->
        "background-image: repeating-linear-gradient(45deg, white 0, white 1px, transparent 0, transparent 50%); background-size: 16px 16px;"

      2 ->
        "background-image: radial-gradient(circle, white 1px, transparent 1px); background-size: 14px 14px;"

      3 ->
        "background-image: linear-gradient(135deg, white 25%, transparent 25%, transparent 50%, white 50%, white 75%, transparent 75%); background-size: 24px 24px;"
    end
  end
end
