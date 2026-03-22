defmodule ElixirEvents.Import.ProfilesTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Import
  alias ElixirEvents.Profiles

  @tag :tmp_dir
  test "imports profiles with social_links", %{tmp_dir: tmp_dir} do
    yaml = """
    - name: "Jose Valim"
      slug: "josevalim"
      bio: "Creator of Elixir"
      social_links:
        - platform: github
          url: "https://github.com/josevalim"
    """

    File.write!(Path.join(tmp_dir, "speakers.yml"), yaml)

    assert :ok = Import.Profiles.run(tmp_dir)
    profile = Profiles.get_profile_by_handle("josevalim")
    assert profile.name == "Jose Valim"
    assert [%{platform: :github}] = profile.social_links
  end
end
