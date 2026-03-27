defmodule ElixirEventsWeb.ProfileLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Claims, Profiles, Talks, Workshops}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"handle" => handle}, uri, socket) do
    case Profiles.get_profile_by_handle(handle) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Profile not found.")
         |> redirect(to: ~p"/speakers")}

      profile ->
        talks =
          Talks.list_talks_for_profile(profile.id,
            preload: [:event, :recordings, talk_speakers: :profile]
          )

        workshops =
          Workshops.list_workshops_for_profile(profile.id,
            preload: [:event, workshop_trainers: :profile]
          )

        current_user = get_current_user(socket)
        claim_state = get_claim_state(current_user, profile)

        {back_to, back_to_title} =
          case ElixirEventsWeb.Helpers.parse_back_link(uri) do
            {path, title} -> {path, title}
            nil -> {nil, nil}
          end

        {:noreply,
         socket
         |> assign(:page_title, profile.name)
         |> assign(:profile, profile)
         |> assign(:talks, talks)
         |> assign(:workshops, workshops)
         |> assign(:claim_state, claim_state)
         |> assign(:back_to, back_to)
         |> assign(:back_to_title, back_to_title)}
    end
  end

  @impl true
  def handle_event("claim_profile", _params, socket) do
    user = get_current_user(socket)
    profile = socket.assigns.profile

    case Claims.create_claim(user, "profile", profile.id) do
      {:ok, _claim} ->
        {:noreply,
         socket
         |> assign(:claim_state, :pending)
         |> put_flash(:info, "Claim submitted — we'll review it shortly.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Something went wrong. Try again.")}
    end
  end

  defp get_current_user(socket) do
    case socket.assigns[:current_scope] do
      %{user: user} -> user
      _ -> nil
    end
  end

  defp get_claim_state(nil, _profile), do: :logged_out

  defp get_claim_state(user, profile) do
    cond do
      profile.user_id == user.id ->
        :owner

      # User already has a pending claim on THIS profile
      match?(%{status: :pending}, Claims.get_user_claim(user, "profile", profile.id)) ->
        :pending

      # User already has an active claim on ANOTHER profile
      Claims.has_active_claim?(user, "profile") ->
        :has_active_claim

      # Profile is owned by someone else
      profile.user_id != nil ->
        :owned_by_other

      # Profile is unclaimed
      true ->
        :unclaimed
    end
  end
end
