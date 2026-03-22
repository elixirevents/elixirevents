defmodule ElixirEvents.Import.TopicsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Import
  alias ElixirEvents.Topics

  @tag :tmp_dir
  test "imports topics from YAML file", %{tmp_dir: tmp_dir} do
    yaml = """
    - name: "Elixir"
      slug: "elixir"
      description: "The Elixir language"
    - name: "Phoenix"
      slug: "phoenix"
    """

    File.write!(Path.join(tmp_dir, "topics.yml"), yaml)

    assert :ok = Import.Topics.run(tmp_dir)
    assert length(Topics.list_topics()) == 2
    assert Topics.get_topic_by_slug("elixir").description == "The Elixir language"
  end

  @tag :tmp_dir
  test "skips when file does not exist", %{tmp_dir: tmp_dir} do
    assert {:ok, :skipped} = Import.Topics.run(tmp_dir)
  end

  @tag :tmp_dir
  test "is idempotent", %{tmp_dir: tmp_dir} do
    yaml = """
    - name: "Elixir"
      slug: "elixir"
    """

    File.write!(Path.join(tmp_dir, "topics.yml"), yaml)

    assert :ok = Import.Topics.run(tmp_dir)
    assert :ok = Import.Topics.run(tmp_dir)
    assert length(Topics.list_topics()) == 1
  end
end
