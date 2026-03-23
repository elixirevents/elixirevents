defmodule ElixirEvents.DataFixtures do
  @moduledoc """
  Test helpers for creating data entities via their contexts.
  """

  alias ElixirEvents.{Events, Organizations, Profiles, Talks, Topics, Venues}

  def unique_slug, do: "slug-#{System.unique_integer([:positive])}"
  def unique_handle, do: "handle#{System.unique_integer([:positive])}"

  def profile_fixture(attrs \\ %{}) do
    {:ok, profile} =
      attrs
      |> Enum.into(%{
        name: "Speaker #{System.unique_integer([:positive])}",
        handle: unique_handle(),
        headline: "Elixir Developer",
        is_speaker: true
      })
      |> Profiles.upsert_profile()

    profile
  end

  def claimed_profile_fixture(user, attrs \\ %{}) do
    profile = profile_fixture(attrs)

    profile
    |> Ecto.Changeset.change(user_id: user.id)
    |> ElixirEvents.Repo.update!()
  end

  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        name: "Topic #{System.unique_integer([:positive])}",
        slug: unique_slug()
      })
      |> Topics.upsert_topic()

    topic
  end

  def venue_fixture(attrs \\ %{}) do
    {:ok, venue} =
      attrs
      |> Enum.into(%{
        name: "Venue #{System.unique_integer([:positive])}",
        slug: unique_slug(),
        city: "Portland"
      })
      |> Venues.upsert_venue()

    venue
  end

  def event_series_fixture(attrs \\ %{}) do
    {:ok, series} =
      attrs
      |> Enum.into(%{
        name: "Series #{System.unique_integer([:positive])}",
        slug: unique_slug(),
        kind: :conference
      })
      |> Events.upsert_event_series()

    series
  end

  def event_fixture(series, attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        name: "Event #{System.unique_integer([:positive])}",
        slug: unique_slug(),
        event_series_id: series.id,
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-01-02],
        timezone: "UTC"
      })
      |> Events.upsert_event()

    event
  end

  def talk_fixture(event, attrs \\ %{}) do
    {:ok, talk} =
      attrs
      |> Enum.into(%{
        title: "Talk #{System.unique_integer([:positive])}",
        slug: unique_slug(),
        event_id: event.id,
        kind: :talk
      })
      |> Talks.upsert_talk()

    talk
  end

  def organization_fixture(attrs \\ %{}) do
    {:ok, org} =
      attrs
      |> Enum.into(%{
        name: "Org #{System.unique_integer([:positive])}",
        slug: unique_slug()
      })
      |> Organizations.upsert_organization()

    org
  end
end
