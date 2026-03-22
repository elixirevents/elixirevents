defmodule ElixirEvents.SubmissionsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Submissions}

  defp create_event(_) do
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

    %{event: event}
  end

  describe "create_cfp/1" do
    setup [:create_event]

    test "creates a CFP", %{event: event} do
      assert {:ok, cfp} =
               Submissions.create_cfp(%{
                 event_id: event.id,
                 name: "Main CFP",
                 url: "https://example.com/cfp",
                 open_date: ~D[2025-03-01],
                 close_date: ~D[2025-05-15]
               })

      assert cfp.name == "Main CFP"
    end

    test "requires event_id and url" do
      assert {:error, changeset} = Submissions.create_cfp(%{})
      assert "can't be blank" in errors_on(changeset).event_id
      assert "can't be blank" in errors_on(changeset).url
    end
  end

  describe "list_cfps/1" do
    setup [:create_event]

    test "returns CFPs for an event", %{event: event} do
      {:ok, _} =
        Submissions.create_cfp(%{event_id: event.id, url: "https://example.com/cfp"})

      assert [_] = Submissions.list_cfps(event.id)
    end
  end

  describe "replace_cfps/2" do
    setup [:create_event]

    test "replaces all CFPs for an event", %{event: event} do
      Submissions.create_cfp(%{event_id: event.id, url: "https://old.com"})

      {:ok, cfps} =
        Submissions.replace_cfps(event.id, [
          %{name: "Main CFP", url: "https://new.com/cfp", open_date: ~D[2025-03-01]}
        ])

      assert length(cfps) == 1
      assert hd(cfps).name == "Main CFP"
    end
  end
end
