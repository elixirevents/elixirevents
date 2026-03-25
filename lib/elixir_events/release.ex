defmodule ElixirEvents.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :elixir_events

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def sync_data do
    load_app()
    Application.ensure_all_started(:req)

    {:ok, _, _} =
      Ecto.Migrator.with_repo(ElixirEvents.Repo, fn _repo ->
        data_dir = Application.app_dir(@app, "priv/data")
        ElixirEvents.Import.Sync.run(data_dir)
      end)
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(:ssl)
    Application.load(@app)
  end
end
