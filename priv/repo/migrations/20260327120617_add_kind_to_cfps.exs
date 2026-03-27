defmodule ElixirEvents.Repo.Migrations.AddKindToCfps do
  use Ecto.Migration

  def change do
    alter table(:cfps) do
      add :kind, :string, default: "talks"
    end
  end
end
