defmodule ElixirEventsWeb.ProfileLive.Edit do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Profiles
  alias ElixirEvents.Profiles.Profile

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    user = socket.assigns.current_scope.user
    profile = Profiles.get_profile_for_user(user.id)

    if profile do
      changeset = Profile.owner_changeset(profile, %{})

      {:noreply,
       socket
       |> assign(:page_title, "Edit Profile")
       |> assign(:profile, profile)
       |> assign_form(changeset)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "No profile linked to your account.")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("validate", %{"profile" => profile_params}, socket) do
    changeset =
      socket.assigns.profile
      |> Profile.owner_changeset(profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"profile" => profile_params}, socket) do
    case Profiles.update_profile_as_owner(socket.assigns.profile, profile_params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated.")
         |> redirect(to: ~p"/profiles/#{profile.handle}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def platform_options do
    [
      {"X", :twitter},
      {"GitHub", :github},
      {"LinkedIn", :linkedin},
      {"Mastodon", :mastodon},
      {"Bluesky", :bluesky},
      {"Instagram", :instagram},
      {"YouTube", :youtube},
      {"Website", :website},
      {"Meetup", :meetup}
    ]
  end
end
