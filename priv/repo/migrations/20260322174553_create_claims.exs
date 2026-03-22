defmodule ElixirEvents.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
    # Add FK constraint from profiles.user_id to users
    # (was added as plain bigint before users table existed)
    alter table(:profiles) do
      modify :user_id, references(:users, on_delete: :nilify_all), from: :bigint
    end

    create table(:claims) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :claimable_type, :string, null: false
      add :claimable_id, :bigint, null: false
      add :status, :string, null: false, default: "pending"
      add :user_notes, :text
      add :admin_notes, :text
      add :reviewed_at, :utc_datetime_usec
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:claims, [:user_id])
    create index(:claims, [:claimable_type, :claimable_id])
    create unique_index(:claims, [:user_id, :claimable_type, :claimable_id])

    create unique_index(:claims, [:user_id, :claimable_type],
             where: "status IN ('pending', 'approved')",
             name: :claims_one_active_per_user_type
           )
  end
end
