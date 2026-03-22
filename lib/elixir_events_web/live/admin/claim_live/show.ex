defmodule ElixirEventsWeb.Admin.ClaimLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Claims, Profiles}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    claim = Claims.get_claim!(id)
    profile = if claim.claimable_type == "profile", do: Profiles.get_profile(claim.claimable_id)

    # All claims on this entity
    all_claims = Claims.list_claims(claimable_type: claim.claimable_type)
    entity_claims = Enum.filter(all_claims, &(&1.claimable_id == claim.claimable_id))

    {:noreply,
     socket
     |> assign(:page_title, "Claim ##{claim.id}")
     |> assign(:claim, claim)
     |> assign(:profile, profile)
     |> assign(:entity_claims, entity_claims)
     |> assign(:admin_notes, "")}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    claim = socket.assigns.claim
    admin = socket.assigns.current_admin

    case Claims.approve_claim(claim, admin) do
      {:ok, updated_claim} ->
        {:noreply,
         socket
         |> assign(:claim, updated_claim)
         |> put_flash(:info, "Claim approved.")}

      {:error, :email_not_confirmed} ->
        {:noreply, put_flash(socket, :error, "Cannot approve: user email not confirmed.")}
    end
  end

  def handle_event("reject", %{"admin_notes" => notes}, socket) do
    claim = socket.assigns.claim
    admin = socket.assigns.current_admin

    case Claims.reject_claim(claim, admin, notes) do
      {:ok, updated_claim} ->
        {:noreply,
         socket
         |> assign(:claim, updated_claim)
         |> put_flash(:info, "Claim rejected.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reject claim.")}
    end
  end

  def handle_event("update_notes", %{"admin_notes" => notes}, socket) do
    {:noreply, assign(socket, :admin_notes, notes)}
  end
end
