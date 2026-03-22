defmodule ElixirEvents.Sponsorship do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Repo
  alias ElixirEvents.Sponsorship.{Sponsor, SponsorTier}

  def list_sponsor_tiers(event_id) do
    SponsorTier
    |> where(event_id: ^event_id)
    |> order_by(:level)
    |> preload(sponsors: :organization)
    |> Repo.all()
  end

  def create_sponsor_tier(attrs) do
    %SponsorTier{}
    |> SponsorTier.changeset(attrs)
    |> Repo.insert()
  end

  def create_sponsor(attrs) do
    %Sponsor{}
    |> Sponsor.changeset(attrs)
    |> Repo.insert()
  end

  def replace_sponsor_tiers(event_id, tiers_attrs) do
    Repo.transaction(fn ->
      from(s in Sponsor,
        join: st in SponsorTier,
        on: s.sponsor_tier_id == st.id,
        where: st.event_id == ^event_id
      )
      |> Repo.delete_all()

      from(st in SponsorTier, where: st.event_id == ^event_id) |> Repo.delete_all()

      Enum.map(tiers_attrs, fn tier_attrs ->
        sponsors_attrs = Map.get(tier_attrs, :sponsors, [])
        tier_only = Map.drop(tier_attrs, [:sponsors])
        {:ok, tier} = create_sponsor_tier(Map.put(tier_only, :event_id, event_id))

        sponsors =
          Enum.map(sponsors_attrs, fn s_attrs ->
            {:ok, sponsor} = create_sponsor(Map.put(s_attrs, :sponsor_tier_id, tier.id))
            sponsor
          end)

        Map.put(tier, :sponsors, sponsors)
      end)
    end)
  end
end
