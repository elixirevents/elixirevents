defmodule ElixirEvents.Search.Collections.ProfileDocument do
  @moduledoc """
  Maps ElixirEvents.Profiles.Profile to a Typesense document.
  Handles the virtual talk_count field (defaults to 0 if not loaded).
  """

  @behaviour ElixirEvents.Search.Indexable

  @impl true
  def collection_name, do: "profiles"

  @impl true
  def to_search_document(%ElixirEvents.Profiles.Profile{} = profile) do
    %{
      id: to_string(profile.id),
      name: profile.name,
      handle: profile.handle,
      headline: profile.headline || "",
      bio: profile.bio || "",
      avatar_url: profile.avatar_url || "",
      city: profile.city || "",
      country_code: profile.country_code || "",
      is_speaker: profile.is_speaker,
      talk_count: profile.talk_count || 0
    }
  end

  @impl true
  def search_schema do
    %{
      name: collection_name(),
      fields: [
        %{name: "name", type: "string", index: true},
        %{name: "handle", type: "string", index: true},
        %{name: "headline", type: "string", index: true, optional: true},
        %{name: "bio", type: "string", index: true, optional: true},
        %{name: "avatar_url", type: "string", index: false, optional: true},
        %{name: "city", type: "string", index: true, optional: true},
        %{name: "country_code", type: "string", facet: true, optional: true},
        %{name: "is_speaker", type: "bool", facet: true},
        %{name: "talk_count", type: "int32", sort: true}
      ],
      default_sorting_field: "talk_count"
    }
  end
end
