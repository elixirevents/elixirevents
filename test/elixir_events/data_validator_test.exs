defmodule ElixirEvents.DataValidatorTest do
  use ExUnit.Case, async: true

  alias ElixirEvents.DataValidator

  @moduletag :tmp_dir

  defp write_yaml(dir, filename, content) do
    path = Path.join(dir, filename)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end

  defp setup_minimal_data(data_dir) do
    write_yaml(data_dir, "speakers.yml", ~S"""
    - name: "Jose Valim"
      slug: "josevalim"
    """)

    write_yaml(data_dir, "topics.yml", ~S"""
    - name: "Elixir"
      slug: "elixir"
    """)
  end

  describe "validate/1 with valid data" do
    test "passes with minimal valid structure", %{tmp_dir: dir} do
      setup_minimal_data(dir)

      series_dir = Path.join(dir, "elixirconf/elixirconf-us-2024")
      File.mkdir_p!(series_dir)

      write_yaml(dir, "elixirconf/series.yml", ~S"""
      name: "ElixirConf"
      slug: "elixirconf"
      kind: conference
      """)

      write_yaml(dir, "elixirconf/elixirconf-us-2024/event.yml", ~S"""
      name: "ElixirConf US 2024"
      slug: "elixirconf-us-2024"
      kind: conference
      status: completed
      format: in_person
      start_date: "2024-08-28"
      end_date: "2024-08-30"
      timezone: "America/Chicago"
      """)

      write_yaml(dir, "elixirconf/elixirconf-us-2024/talks.yml", ~S"""
      - title: "Keynote"
        slug: "keynote-jose"
        kind: keynote
        speakers:
          - josevalim
        topics:
          - elixir
      """)

      assert {:ok, %{series: 1}} = DataValidator.validate(dir)
    end
  end

  describe "validate/1 catches errors" do
    test "detects missing required fields in series.yml", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      series_dir = Path.join(dir, "bad-series")
      File.mkdir_p!(series_dir)

      write_yaml(dir, "bad-series/series.yml", ~S"""
      slug: "bad-series"
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert "missing required field 'name'" in messages
      assert "missing required field 'kind'" in messages
    end

    test "detects invalid enum values in event.yml", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: rave
      status: vibing
      format: telepathy
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "invalid kind: 'rave'"))
      assert Enum.any?(messages, &String.contains?(&1, "invalid status: 'vibing'"))
      assert Enum.any?(messages, &String.contains?(&1, "invalid format: 'telepathy'"))
    end

    test "detects invalid slug format", %{tmp_dir: dir} do
      write_yaml(dir, "speakers.yml", ~S"""
      - name: "Bad Speaker"
        slug: "bad_speaker!"
      """)

      write_yaml(dir, "topics.yml", ~S"""
      - name: "Good"
        slug: "good"
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "invalid slug 'bad_speaker!'"))
    end

    test "detects duplicate slugs in speakers.yml", %{tmp_dir: dir} do
      write_yaml(dir, "speakers.yml", ~S"""
      - name: "Alice"
        slug: "alice"
      - name: "Alice Copy"
        slug: "alice"
      """)

      write_yaml(dir, "topics.yml", "[]")

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "duplicate slug 'alice'"))
    end

    test "detects invalid talk kind", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/talks.yml", ~S"""
      - title: "My Talk"
        slug: "my-talk"
        kind: fireside_chat
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "invalid kind: 'fireside_chat'"))
    end

    test "detects missing speaker reference", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/talks.yml", ~S"""
      - title: "Talk"
        slug: "talk"
        kind: talk
        speakers:
          - nonexistent-speaker
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "speaker 'nonexistent-speaker' not found"))
    end

    test "detects duplicate talk slugs within same event", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/talks.yml", ~S"""
      - title: "Talk A"
        slug: "same-slug"
        kind: talk
      - title: "Talk B"
        slug: "same-slug"
        kind: talk
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "duplicate talk slug 'same-slug'"))
    end

    test "detects YAML parse errors", %{tmp_dir: dir} do
      write_yaml(dir, "speakers.yml", "- name: \"broken\nyaml")
      write_yaml(dir, "topics.yml", "[]")

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "YAML parse error"))
    end

    test "detects unknown keys in speaker", %{tmp_dir: dir} do
      write_yaml(dir, "speakers.yml", ~S"""
      - name: "Alice"
        slug: "alice"
        favourite_color: "purple"
      """)

      write_yaml(dir, "topics.yml", "[]")

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)

      assert Enum.any?(
               messages,
               &String.contains?(&1, "unknown key 'favourite_color' in speaker")
             )
    end

    test "detects unknown keys in event", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      capacity: 500
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "unknown key 'capacity' in event"))
    end

    test "detects unknown keys in talk", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/talks.yml", ~S"""
      - title: "Talk"
        slug: "talk"
        kind: talk
        rating: 5
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "unknown key 'rating' in talk"))
    end

    test "detects invalid URL in speaker website", %{tmp_dir: dir} do
      write_yaml(dir, "speakers.yml", ~S"""
      - name: "Alice"
        slug: "alice"
        website: "not-a-url"
      """)

      write_yaml(dir, "topics.yml", "[]")

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "invalid URL for 'website'"))
    end

    test "detects invalid social_links platform", %{tmp_dir: dir} do
      write_yaml(dir, "speakers.yml", ~S"""
      - name: "Alice"
        slug: "alice"
        social_links:
          - platform: tiktok
            url: "https://tiktok.com/@alice"
      """)

      write_yaml(dir, "topics.yml", "[]")

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "invalid platform: 'tiktok'"))
    end

    test "detects invalid recording provider", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/talks.yml", ~S"""
      - title: "Talk"
        slug: "talk"
        kind: talk
        recordings:
          - provider: dailymotion
            url: "https://dailymotion.com/video/123"
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "invalid provider: 'dailymotion'"))
    end

    test "detects unknown keys in recording", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/talks.yml", ~S"""
      - title: "Talk"
        slug: "talk"
        kind: talk
        recordings:
          - provider: youtube
            url: "https://youtube.com/watch?v=123"
            views: 1000
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "unknown key 'views' in recording"))
    end

    test "detects invalid sponsor badge", %{tmp_dir: dir} do
      setup_minimal_data(dir)

      write_yaml(dir, "organizations.yml", ~S"""
      - name: "Acme"
        slug: "acme"
      """)

      write_yaml(dir, "venues.yml", "[]")
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/sponsors.yml", ~S"""
      - name: "Gold"
        level: 1
        sponsors:
          - slug: "acme"
            badge: vip
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "invalid badge: 'vip'"))
    end

    test "detects unknown keys in social_link", %{tmp_dir: dir} do
      write_yaml(dir, "speakers.yml", ~S"""
      - name: "Alice"
        slug: "alice"
        social_links:
          - platform: github
            url: "https://github.com/alice"
            followers: 100
      """)

      write_yaml(dir, "topics.yml", "[]")

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "unknown key 'followers' in social_link"))
    end

    test "detects invalid duration type in talk", %{tmp_dir: dir} do
      setup_minimal_data(dir)
      File.mkdir_p!(Path.join(dir, "s/e"))

      write_yaml(dir, "s/series.yml", ~S"""
      name: "S"
      slug: "s"
      kind: conference
      """)

      write_yaml(dir, "s/e/event.yml", ~S"""
      name: "E"
      slug: "e"
      kind: conference
      status: completed
      format: online
      start_date: "2024-01-01"
      end_date: "2024-01-02"
      timezone: "UTC"
      """)

      write_yaml(dir, "s/e/talks.yml", ~S"""
      - title: "Talk"
        slug: "talk"
        kind: talk
        duration: "thirty minutes"
      """)

      assert {:error, errors} = DataValidator.validate(dir)
      messages = Enum.map(errors, & &1.message)
      assert Enum.any?(messages, &String.contains?(&1, "'duration' must be an integer"))
    end
  end
end
