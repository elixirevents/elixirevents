defmodule ElixirEventsWeb.Admin.ClaimLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Claims, Profiles}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    status_filter = params["status"]

    opts =
      if status_filter && status_filter != "",
        do: [status: String.to_existing_atom(status_filter)],
        else: []

    claims = Claims.list_claims(opts)

    claims_with_context =
      Enum.map(claims, fn claim ->
        profile =
          if claim.claimable_type == "profile", do: Profiles.get_profile(claim.claimable_id)

        existing_owner = Claims.get_approved_claim(claim.claimable_type, claim.claimable_id)
        is_dispute = existing_owner != nil and existing_owner.id != claim.id

        %{claim: claim, profile: profile, is_dispute: is_dispute}
      end)

    {:noreply,
     socket
     |> assign(:page_title, "Claims")
     |> assign(:claims, claims_with_context)
     |> assign(:status_filter, status_filter)}
  end
end
