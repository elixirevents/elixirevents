defmodule ElixirEvents.Search.Collections.TalkDocument do
  @moduledoc """
  Maps ElixirEvents.Talks.Talk to a Typesense document.
  Denormalizes speaker names and event name/slug from associations.
  Requires preloads: [talk_speakers: :profile, event: []]
  """

  @behaviour ElixirEvents.Search.Indexable

  @impl true
  def collection_name, do: "talks"

  @impl true
  def to_search_document(%ElixirEvents.Talks.Talk{} = talk) do
    speaker_names =
      talk.talk_speakers
      |> Enum.map(& &1.profile.name)

    thumbnail_url = ElixirEventsWeb.Helpers.talk_thumbnail_url(talk)

    %{
      id: to_string(talk.id),
      title: talk.title,
      slug: talk.slug,
      abstract: talk.abstract || "",
      kind: to_string(talk.kind),
      level: if(talk.level, do: to_string(talk.level), else: ""),
      duration: talk.duration || 0,
      event_name: talk.event.name,
      event_slug: talk.event.slug,
      speaker_names: speaker_names,
      thumbnail_url: thumbnail_url || ""
    }
  end

  @impl true
  def search_schema do
    %{
      name: collection_name(),
      fields: [
        %{name: "title", type: "string", index: true},
        %{name: "slug", type: "string", index: false},
        %{name: "abstract", type: "string", index: true, optional: true},
        %{name: "kind", type: "string", facet: true, index: true},
        %{name: "level", type: "string", facet: true, index: true, optional: true},
        %{name: "duration", type: "int32", index: false, optional: true},
        %{name: "event_name", type: "string", index: true},
        %{name: "event_slug", type: "string", index: false},
        %{name: "speaker_names", type: "string[]", index: true},
        %{name: "thumbnail_url", type: "string", index: false, optional: true}
      ]
    }
  end
end
