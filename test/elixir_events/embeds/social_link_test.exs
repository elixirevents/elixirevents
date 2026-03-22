defmodule ElixirEvents.Embeds.SocialLinkTest do
  use ExUnit.Case, async: true

  alias ElixirEvents.Embeds.SocialLink

  describe "changeset/2" do
    test "valid changeset with all fields" do
      changeset =
        SocialLink.changeset(%SocialLink{}, %{
          platform: :github,
          url: "https://github.com/josevalim",
          label: "GitHub"
        })

      assert changeset.valid?
    end

    test "requires platform and url" do
      changeset = SocialLink.changeset(%SocialLink{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).platform
      assert "can't be blank" in errors_on(changeset).url
    end

    test "rejects invalid platform" do
      changeset =
        SocialLink.changeset(%SocialLink{}, %{
          platform: :tiktok,
          url: "https://tiktok.com/@foo"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).platform
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
