defmodule ElixirEvents.Claims do
  @moduledoc false

  import Ecto.Query

  alias ElixirEvents.Claims.Claim
  alias ElixirEvents.Profiles.Profile
  alias ElixirEvents.Repo

  def create_claim(user, claimable_type, claimable_id, attrs \\ %{}) do
    %Claim{}
    |> Claim.changeset(
      Map.merge(attrs, %{
        user_id: user.id,
        claimable_type: claimable_type,
        claimable_id: claimable_id
      })
    )
    |> Repo.insert()
  end

  def approve_claim(claim, admin) do
    claim = Repo.preload(claim, :user)

    if is_nil(claim.user.confirmed_at) do
      {:error, :email_not_confirmed}
    else
      Repo.transaction(fn ->
        # Revoke any existing approved claim on same entity
        from(c in Claim,
          where:
            c.claimable_type == ^claim.claimable_type and
              c.claimable_id == ^claim.claimable_id and
              c.status == :approved and
              c.id != ^claim.id
        )
        |> Repo.update_all(
          set: [status: :revoked, reviewed_at: DateTime.utc_now(), reviewed_by_id: admin.id]
        )

        # For profile claims: merge profiles
        if claim.claimable_type == "profile" do
          # Delete user's auto-created registration profile
          from(p in Profile,
            where: p.user_id == ^claim.user.id and p.id != ^claim.claimable_id
          )
          |> Repo.delete_all()

          # Set user_id on claimed profile
          Repo.get!(Profile, claim.claimable_id)
          |> Ecto.Changeset.change(user_id: claim.user.id)
          |> Repo.update!()
        end

        # Update claim status
        claim
        |> Claim.changeset(%{
          status: :approved,
          reviewed_at: DateTime.utc_now(),
          reviewed_by_id: admin.id
        })
        |> Repo.update!()
      end)
    end
  end

  def reject_claim(claim, admin, admin_notes \\ nil) do
    claim
    |> Claim.changeset(%{
      status: :rejected,
      admin_notes: admin_notes,
      reviewed_at: DateTime.utc_now(),
      reviewed_by_id: admin.id
    })
    |> Repo.update()
  end

  def revoke_claim(claim) do
    claim
    |> Claim.changeset(%{status: :revoked})
    |> Repo.update()
  end

  def list_claims(opts \\ []) do
    Claim
    |> maybe_filter_status(opts[:status])
    |> maybe_filter_claimable_type(opts[:claimable_type])
    |> order_by([c], desc: c.inserted_at)
    |> preload([:user, :reviewed_by])
    |> Repo.all()
  end

  def list_pending_claims do
    list_claims(status: :pending)
  end

  def get_claim!(id) do
    Claim
    |> preload([:user, :reviewed_by])
    |> Repo.get!(id)
  end

  def get_approved_claim(claimable_type, claimable_id) do
    Repo.get_by(Claim,
      claimable_type: claimable_type,
      claimable_id: claimable_id,
      status: :approved
    )
  end

  def get_user_claim(user, claimable_type, claimable_id) do
    Repo.get_by(Claim,
      user_id: user.id,
      claimable_type: claimable_type,
      claimable_id: claimable_id
    )
  end

  def claimed_by?(user, claimable_type, claimable_id) do
    from(c in Claim,
      where:
        c.user_id == ^user.id and
          c.claimable_type == ^claimable_type and
          c.claimable_id == ^claimable_id and
          c.status == :approved
    )
    |> Repo.exists?()
  end

  def claimed?(claimable_type, claimable_id) do
    from(c in Claim,
      where:
        c.claimable_type == ^claimable_type and
          c.claimable_id == ^claimable_id and
          c.status == :approved
    )
    |> Repo.exists?()
  end

  def has_active_claim?(user, claimable_type) do
    from(c in Claim,
      where:
        c.user_id == ^user.id and
          c.claimable_type == ^claimable_type and
          c.status in [:pending, :approved]
    )
    |> Repo.exists?()
  end

  defp maybe_filter_status(queryable, nil), do: queryable

  defp maybe_filter_status(queryable, status) do
    from(c in queryable, where: c.status == ^status)
  end

  defp maybe_filter_claimable_type(queryable, nil), do: queryable

  defp maybe_filter_claimable_type(queryable, type) do
    from(c in queryable, where: c.claimable_type == ^type)
  end
end
