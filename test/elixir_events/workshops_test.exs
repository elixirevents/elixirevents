defmodule ElixirEvents.WorkshopsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Profiles, Workshops}

  defp create_event(_) do
    {:ok, event} =
      Events.create_event(%{
        name: "Test Conf",
        slug: "test-conf",
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2026-05-18],
        end_date: ~D[2026-05-20],
        timezone: "Europe/Stockholm"
      })

    %{event: event}
  end

  defp create_profile(_) do
    {:ok, profile} = Profiles.create_profile(%{name: "Jose Valim", handle: "josevalim"})
    %{profile: profile}
  end

  describe "upsert_workshop/1" do
    setup [:create_event]

    test "creates a workshop with valid attrs", %{event: event} do
      assert {:ok, workshop} =
               Workshops.upsert_workshop(%{
                 event_id: event.id,
                 title: "Intro to LiveView",
                 slug: "intro-to-liveview",
                 start_date: ~D[2026-05-18],
                 end_date: ~D[2026-05-18]
               })

      assert workshop.title == "Intro to LiveView"
      assert workshop.slug == "intro-to-liveview"
    end

    test "upserts on conflict — same id, updated title", %{event: event} do
      {:ok, _} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Intro to LiveView",
          slug: "intro-to-liveview",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      {:ok, updated} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Advanced LiveView",
          slug: "intro-to-liveview",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      assert updated.title == "Advanced LiveView"
      assert [_only_one] = Workshops.list_workshops_for_event(event.id)
    end

    test "requires event_id, title, slug, start_date, end_date" do
      assert {:error, changeset} = Workshops.upsert_workshop(%{})
      assert "can't be blank" in errors_on(changeset).event_id
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).slug
      assert "can't be blank" in errors_on(changeset).start_date
      assert "can't be blank" in errors_on(changeset).end_date
    end
  end

  describe "list_workshops_for_event/1" do
    setup [:create_event]

    test "returns workshops ordered by start_date asc then title asc", %{event: event} do
      {:ok, _} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Zebra Workshop",
          slug: "zebra-workshop",
          start_date: ~D[2026-05-19],
          end_date: ~D[2026-05-19]
        })

      {:ok, _} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Alpha Workshop",
          slug: "alpha-workshop",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      {:ok, _} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Beta Workshop",
          slug: "beta-workshop",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      workshops = Workshops.list_workshops_for_event(event.id)
      titles = Enum.map(workshops, & &1.title)
      assert titles == ["Alpha Workshop", "Beta Workshop", "Zebra Workshop"]
    end

    test "returns empty list when no workshops exist", %{event: event} do
      assert [] = Workshops.list_workshops_for_event(event.id)
    end
  end

  describe "get_workshop_by_event_and_slug/3" do
    setup [:create_event]

    test "finds a workshop by event slug and workshop slug", %{event: event} do
      {:ok, workshop} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Ecto Deep Dive",
          slug: "ecto-deep-dive",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      found = Workshops.get_workshop_by_event_and_slug("test-conf", "ecto-deep-dive")
      assert found.id == workshop.id
    end

    test "returns nil for nonexistent combination" do
      assert nil == Workshops.get_workshop_by_event_and_slug("no-event", "no-workshop")
    end
  end

  describe "delete_orphaned_workshops/2" do
    setup [:create_event]

    test "deletes workshops not in slug list", %{event: event} do
      {:ok, _keep} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Keep Me",
          slug: "keep-me",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      {:ok, _delete} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Delete Me",
          slug: "delete-me",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      Workshops.delete_orphaned_workshops(event.id, ["keep-me"])

      remaining = Workshops.list_workshops_for_event(event.id)
      assert [%{slug: "keep-me"}] = remaining
    end
  end

  describe "replace_workshop_trainers/2" do
    setup [:create_event, :create_profile]

    test "replaces trainers for a workshop", %{event: event, profile: profile} do
      {:ok, workshop} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Trainer Workshop",
          slug: "trainer-workshop",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      {:ok, trainers} =
        Workshops.replace_workshop_trainers(workshop.id, [
          %{profile_id: profile.id, position: 1}
        ])

      assert length(trainers) == 1
      assert hd(trainers).profile_id == profile.id
    end

    test "replaces existing trainers with new ones", %{event: event, profile: profile} do
      {:ok, profile2} = Profiles.create_profile(%{name: "Chris McCord", handle: "chrismccord"})

      {:ok, workshop} =
        Workshops.upsert_workshop(%{
          event_id: event.id,
          title: "Replace Trainers Workshop",
          slug: "replace-trainers-workshop",
          start_date: ~D[2026-05-18],
          end_date: ~D[2026-05-18]
        })

      {:ok, _} =
        Workshops.replace_workshop_trainers(workshop.id, [
          %{profile_id: profile.id, position: 1}
        ])

      {:ok, trainers} =
        Workshops.replace_workshop_trainers(workshop.id, [
          %{profile_id: profile2.id, position: 1}
        ])

      assert length(trainers) == 1
      assert hd(trainers).profile_id == profile2.id
    end
  end
end
