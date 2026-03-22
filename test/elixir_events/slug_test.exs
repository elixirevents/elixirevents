defmodule ElixirEvents.SlugTest do
  use ExUnit.Case, async: true

  alias ElixirEvents.Slug

  describe "slugify/1" do
    test "converts string to lowercase slug" do
      assert Slug.slugify("Hello World") == "hello-world"
    end

    test "replaces special characters with hyphens" do
      assert Slug.slugify("Acme Inc.") == "acme-inc"
    end

    test "collapses multiple hyphens" do
      assert Slug.slugify("hello---world") == "hello-world"
    end

    test "strips leading and trailing hyphens" do
      assert Slug.slugify("-hello-") == "hello"
      assert Slug.slugify("--hello--") == "hello"
    end

    test "handles unicode characters" do
      assert Slug.slugify("café résumé") == "caf-r-sum"
    end

    test "returns nil for non-string input" do
      assert Slug.slugify(nil) == nil
      assert Slug.slugify(123) == nil
    end

    test "handles conference-style names" do
      assert Slug.slugify("ElixirConf US 2024") == "elixirconf-us-2024"
      assert Slug.slugify("Code BEAM Lite") == "code-beam-lite"
    end

    test "handles speaker names" do
      assert Slug.slugify("José Valim") == "jos-valim"
      assert Slug.slugify("Chris McCord") == "chris-mccord"
    end
  end

  describe "maybe_generate_slug/2" do
    test "generates slug from name when slug not provided" do
      changeset =
        {%{}, %{name: :string, slug: :string}}
        |> Ecto.Changeset.cast(%{name: "Hello World"}, [:name, :slug])
        |> Slug.maybe_generate_slug()

      assert Ecto.Changeset.get_change(changeset, :slug) == "hello-world"
    end

    test "preserves explicit slug" do
      changeset =
        {%{}, %{name: :string, slug: :string}}
        |> Ecto.Changeset.cast(%{name: "Hello World", slug: "custom-slug"}, [:name, :slug])
        |> Slug.maybe_generate_slug()

      assert Ecto.Changeset.get_change(changeset, :slug) == "custom-slug"
    end

    test "generates slug from custom source field" do
      changeset =
        {%{}, %{title: :string, slug: :string}}
        |> Ecto.Changeset.cast(%{title: "My Great Talk"}, [:title, :slug])
        |> Slug.maybe_generate_slug(:title)

      assert Ecto.Changeset.get_change(changeset, :slug) == "my-great-talk"
    end

    test "does nothing when source field is also missing" do
      changeset =
        {%{}, %{name: :string, slug: :string}}
        |> Ecto.Changeset.cast(%{}, [:name, :slug])
        |> Slug.maybe_generate_slug()

      refute Ecto.Changeset.get_change(changeset, :slug)
    end
  end

  describe "validate_slug_format/2" do
    defp changeset_for(slug) do
      {%{}, %{slug: :string}}
      |> Ecto.Changeset.cast(%{slug: slug}, [:slug])
      |> Slug.validate_slug_format()
    end

    test "accepts valid slugs" do
      for slug <- ~w(beatz my-org abc123 hello-world-123 elixirconf-us-2024) do
        assert changeset_for(slug).valid?, "expected #{slug} to be valid"
      end
    end

    test "rejects slugs with uppercase letters" do
      refute changeset_for("Hello").valid?
    end

    test "rejects slugs with invalid characters" do
      for slug <- ~w(hello_world hello.world hello@world hello!world my+org) do
        refute changeset_for(slug).valid?, "expected #{slug} to be invalid"
      end
    end

    test "rejects slugs with leading hyphen" do
      refute changeset_for("-hello").valid?
    end

    test "rejects slugs with trailing hyphen" do
      refute changeset_for("hello-").valid?
    end

    test "rejects slugs with consecutive hyphens" do
      refute changeset_for("hello--world").valid?
    end
  end
end
