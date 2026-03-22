defmodule ElixirEvents.Claims.Claim do
  @moduledoc false

  use ElixirEvents.Schema

  @statuses [:pending, :approved, :rejected, :revoked]

  @permitted ~w(user_id claimable_type claimable_id status user_notes admin_notes
                reviewed_at reviewed_by_id)a
  @required ~w(user_id claimable_type claimable_id status)a

  schema "claims" do
    field :claimable_type, :string
    field :claimable_id, :id
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :user_notes, :string
    field :admin_notes, :string
    field :reviewed_at, :utc_datetime_usec

    belongs_to :user, ElixirEvents.Accounts.User
    belongs_to :reviewed_by, ElixirEvents.Accounts.User

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> validate_inclusion(:claimable_type, ["profile", "organization"])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :claimable_type, :claimable_id])
    |> unique_constraint([:user_id, :claimable_type],
      name: :claims_one_active_per_user_type,
      message: "you already have an active claim"
    )
  end
end
