defmodule ElixirEvents.Profiles.Profile do
  @moduledoc false

  use ElixirEvents.Schema

  alias ElixirEvents.Embeds.SocialLink

  @handle_pattern ~r/^[a-z0-9]+$/

  @permitted ~w(name handle headline bio website avatar_url is_speaker)a
  @required ~w(name handle)a

  schema "profiles" do
    field :name, :string
    field :handle, :string
    field :headline, :string
    field :bio, :string
    field :website, :string
    field :avatar_url, :string
    field :is_speaker, :boolean, default: false
    field :talk_count, :integer, virtual: true

    belongs_to :user, ElixirEvents.Accounts.User
    embeds_many :social_links, SocialLink, on_replace: :delete
    has_many :talk_speakers, ElixirEvents.Talks.TalkSpeaker, foreign_key: :profile_id

    timestamps()
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @permitted ++ [:user_id])
    |> maybe_generate_handle()
    |> validate_required(@required)
    |> validate_format(:handle, @handle_pattern,
      message: "must be lowercase letters and numbers only, no special characters"
    )
    |> unique_constraint(:handle)
    |> cast_embed(:social_links, with: &SocialLink.changeset/2)
  end

  def owner_changeset(profile, attrs) do
    profile
    |> cast(attrs, ~w(headline bio website avatar_url is_speaker)a)
    |> cast_embed(:social_links,
      with: &SocialLink.changeset/2,
      sort_param: :social_links_sort,
      drop_param: :social_links_drop
    )
  end

  defp maybe_generate_handle(changeset) do
    case Ecto.Changeset.get_change(changeset, :handle) do
      nil ->
        case Ecto.Changeset.get_change(changeset, :name) ||
               Ecto.Changeset.get_field(changeset, :name) do
          nil -> changeset
          name -> Ecto.Changeset.put_change(changeset, :handle, handleize(name))
        end

      _handle ->
        changeset
    end
  end

  defp handleize(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
