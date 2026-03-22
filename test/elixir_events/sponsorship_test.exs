defmodule ElixirEvents.SponsorshipTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Organizations, Sponsorship}

  defp create_event_and_org(_) do
    {:ok, event} =
      Events.create_event(%{
        name: "Conf",
        slug: "conf",
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2025-01-01],
        end_date: ~D[2025-01-02],
        timezone: "UTC"
      })

    {:ok, org} = Organizations.create_organization(%{name: "Fly.io", slug: "fly-io"})
    %{event: event, org: org}
  end

  describe "list_sponsor_tiers/1" do
    setup [:create_event_and_org]

    test "returns tiers for an event ordered by level with sponsors preloaded", %{
      event: event,
      org: org
    } do
      {:ok, tier} = Sponsorship.create_sponsor_tier(%{event_id: event.id, name: "Gold", level: 2})
      {:ok, _} = Sponsorship.create_sponsor(%{sponsor_tier_id: tier.id, organization_id: org.id})

      {:ok, _} =
        Sponsorship.create_sponsor_tier(%{event_id: event.id, name: "Platinum", level: 1})

      tiers = Sponsorship.list_sponsor_tiers(event.id)
      assert [%{name: "Platinum", sponsors: []}, %{name: "Gold", sponsors: [_]}] = tiers
    end
  end

  describe "sponsor_tiers" do
    setup [:create_event_and_org]

    test "creates a tier", %{event: event} do
      assert {:ok, tier} =
               Sponsorship.create_sponsor_tier(%{
                 event_id: event.id,
                 name: "Platinum",
                 level: 1
               })

      assert tier.name == "Platinum"
    end

    test "enforces unique level per event", %{event: event} do
      attrs = %{event_id: event.id, name: "Platinum", level: 1}
      {:ok, _} = Sponsorship.create_sponsor_tier(attrs)
      assert {:error, changeset} = Sponsorship.create_sponsor_tier(attrs)
      assert "has already been taken" in errors_on(changeset).level
    end
  end

  describe "sponsors" do
    setup [:create_event_and_org]

    test "creates a sponsor", %{event: event, org: org} do
      {:ok, tier} =
        Sponsorship.create_sponsor_tier(%{event_id: event.id, name: "Platinum", level: 1})

      assert {:ok, sponsor} =
               Sponsorship.create_sponsor(%{
                 sponsor_tier_id: tier.id,
                 organization_id: org.id,
                 badge: :keynote
               })

      assert sponsor.badge == :keynote
    end

    test "enforces unique org per tier", %{event: event, org: org} do
      {:ok, tier} =
        Sponsorship.create_sponsor_tier(%{event_id: event.id, name: "Gold", level: 2})

      {:ok, _} = Sponsorship.create_sponsor(%{sponsor_tier_id: tier.id, organization_id: org.id})

      assert {:error, changeset} =
               Sponsorship.create_sponsor(%{sponsor_tier_id: tier.id, organization_id: org.id})

      assert "has already been taken" in errors_on(changeset).sponsor_tier_id
    end
  end

  describe "replace_sponsor_tiers/2" do
    setup [:create_event_and_org]

    test "replaces all tiers and sponsors for an event", %{event: event, org: org} do
      Sponsorship.create_sponsor_tier(%{event_id: event.id, name: "Old", level: 99})

      tiers_attrs = [
        %{name: "Platinum", level: 1, sponsors: [%{organization_id: org.id, badge: :keynote}]}
      ]

      assert {:ok, tiers} = Sponsorship.replace_sponsor_tiers(event.id, tiers_attrs)
      assert length(tiers) == 1
      assert hd(tiers).name == "Platinum"
    end
  end
end
