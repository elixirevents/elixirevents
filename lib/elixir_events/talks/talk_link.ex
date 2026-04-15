defmodule ElixirEvents.Talks.TalkLink do
  @moduledoc false

  use ElixirEvents.Schema

  @kinds [:slides, :repo, :blog_post, :other]

  def kinds, do: @kinds

  @permitted ~w(talk_id kind url label)a
  @required ~w(talk_id kind url)a

  schema "talk_links" do
    field :kind, Ecto.Enum, values: @kinds
    field :url, :string
    field :label, :string

    belongs_to :talk, ElixirEvents.Talks.Talk

    timestamps()
  end

  def changeset(talk_link, attrs) do
    talk_link
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:talk_id)
  end
end
