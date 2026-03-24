defmodule ElixirEventsWeb.UserLive.Registration do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Accounts
  alias ElixirEvents.Accounts.User
  alias ElixirEvents.Profiles

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <div class="mb-10">
          <h1 class="font-display text-3xl font-bold text-base-content">Create an account</h1>
          <p class="text-base-content/55 mt-2">
            Already have an account?
            <.link
              navigate={~p"/login"}
              class="font-semibold text-primary hover:text-primary/70"
            >
              Sign in
            </.link>
          </p>
        </div>

        <div class="p-6 rounded-2xl bg-base-200/30 border border-base-300/50">
          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
            <.input field={@form[:first_name]} type="text" label="First name" required />
            <.input field={@form[:last_name]} type="text" label="Last name" required />
            <.input
              field={@form[:handle]}
              type="text"
              label="Handle"
              required
              placeholder="e.g. josevalim"
              phx-debounce="500"
            />

            <.handle_conflict_notice
              handle_conflict={@handle_conflict}
              claim_profile={@claim_profile}
              suggested_handle={@suggested_handle}
              claim_user_notes={@claim_user_notes}
            />

            <.input field={@form[:email]} type="email" label="Email" autocomplete="username" required />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="new-password"
              required
            />
            <.button size="lg" class="mt-2" phx-disable-with="Creating account...">
              Create an account
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp handle_conflict_notice(%{handle_conflict: nil} = assigns) do
    ~H"""
    """
  end

  defp handle_conflict_notice(%{handle_conflict: {:unclaimed, _profile}} = assigns) do
    ~H"""
    <div class="mt-1 mb-4 pl-4 border-l-2 border-primary/50 space-y-2">
      <p class="text-sm text-base-content/70">
        The handle <span class="font-mono text-primary">{elem(@handle_conflict, 1).handle}</span>
        belongs to speaker <strong class="text-base-content">{elem(@handle_conflict, 1).name}</strong>.
      </p>
      <p :if={@suggested_handle} class="text-sm text-base-content/55">
        Register with <span class="font-mono text-primary">{@suggested_handle}</span> for now.
        If you claim the speaker profile below, we'll merge your account once approved
        — you'll get the original handle and all associated talks.
      </p>

      <label class="flex items-center gap-2 cursor-pointer">
        <input
          type="checkbox"
          name="claim_profile"
          value="true"
          checked={@claim_profile}
          phx-click="toggle_claim"
          class="checkbox checkbox-sm"
        />
        <span class="text-sm text-base-content">
          Claim this speaker profile
        </span>
      </label>

      <div :if={@claim_profile}>
        <textarea
          name="claim_user_notes"
          rows="2"
          maxlength="1000"
          class="w-full input bg-base-200/50 border-base-300 focus:border-primary focus:outline-none focus:ring-0 text-sm text-base-content placeholder:text-base-content/30 py-2"
          placeholder="How can we verify it's you? e.g. your Twitter/GitHub handle so we can reach out"
        >{@claim_user_notes}</textarea>
        <p class="text-xs text-base-content/40 mt-1">
          We'll review your claim after you confirm your email.
        </p>
      </div>
    </div>
    """
  end

  defp handle_conflict_notice(%{handle_conflict: {:claimed, _profile}} = assigns) do
    ~H"""
    <div class="mt-1 mb-4 pl-4 border-l-2 border-amber-500/50 space-y-2">
      <p class="text-sm text-base-content/70">
        This handle belongs to someone else. If this is actually you, you can dispute it.
      </p>
      <p :if={@suggested_handle} class="text-sm text-base-content/55">
        Register with <span class="font-mono text-primary">{@suggested_handle}</span> for now.
        If your dispute is approved, we'll transfer the profile to your account.
      </p>

      <label class="flex items-center gap-2 cursor-pointer">
        <input
          type="checkbox"
          name="claim_profile"
          value="true"
          checked={@claim_profile}
          phx-click="toggle_claim"
          class="checkbox checkbox-sm"
        />
        <span class="text-sm text-base-content">
          Dispute this profile
        </span>
      </label>

      <div :if={@claim_profile}>
        <textarea
          name="claim_user_notes"
          rows="2"
          maxlength="1000"
          class="w-full input bg-base-200/50 border-base-300 focus:border-primary focus:outline-none focus:ring-0 text-sm text-base-content placeholder:text-base-content/30 py-2"
          placeholder="How can we verify it's you? e.g. your Twitter/GitHub handle so we can reach out"
        >{@claim_user_notes}</textarea>
        <p class="text-xs text-base-content/40 mt-1">
          We'll review your claim after you confirm your email.
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: ElixirEventsWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    socket =
      socket
      |> assign(
        handle_conflict: nil,
        claim_profile: false,
        suggested_handle: nil,
        claim_user_notes: ""
      )
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", params, socket) do
    user_params = params["user"]
    claim_profile = params["claim_profile"] == "true"
    claim_user_notes = params["claim_user_notes"]

    opts =
      case {claim_profile, socket.assigns.handle_conflict} do
        {true, {_status, profile}} ->
          opts = [claim_profile_id: profile.id]

          if claim_user_notes && claim_user_notes != "",
            do: opts ++ [claim_user_notes: claim_user_notes],
            else: opts

        _ ->
          []
      end

    case Accounts.register_user(user_params, opts) do
      {:ok, user} ->
        Accounts.deliver_confirmation_instructions(
          user,
          &url(~p"/confirm/#{&1}")
        )

        flash_msg =
          if opts[:claim_profile_id] do
            {_, profile} = socket.assigns.handle_conflict

            "Welcome! Claim submitted for \"#{profile.name}\". " <>
              "Confirm your email at #{user.email} to proceed."
          else
            "Account created! Check your inbox at #{user.email} for a confirmation link."
          end

        {:noreply,
         socket
         |> put_flash(:info, flash_msg)
         |> push_navigate(to: ~p"/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", params, socket) do
    user_params = params["user"] || %{}
    handle = (user_params["handle"] || "") |> String.downcase()
    user_params = Map.put(user_params, "handle", handle)

    {handle_conflict, claim_profile, suggested_handle, user_params} =
      detect_handle_conflict(
        handle,
        socket.assigns.handle_conflict,
        socket.assigns.suggested_handle,
        user_params
      )

    changeset = Accounts.change_user_registration(%User{}, user_params, validate_unique: false)

    {:noreply,
     socket
     |> assign(
       handle_conflict: handle_conflict,
       claim_profile: claim_profile,
       suggested_handle: suggested_handle,
       claim_user_notes: params["claim_user_notes"] || socket.assigns.claim_user_notes
     )
     |> assign_form(Map.put(changeset, :action, :validate))}
  end

  def handle_event("toggle_claim", _params, socket) do
    {:noreply, assign(socket, claim_profile: !socket.assigns.claim_profile)}
  end

  defp detect_handle_conflict(handle, current_conflict, current_suggested, user_params)
       when handle != "" do
    case Profiles.get_profile_by_handle_with_owner_status(handle) do
      nil ->
        {nil, false, nil, user_params}

      {status, _profile} = conflict ->
        if is_nil(current_conflict) do
          # First detection: compute suggested handle and swap in params
          suggested = Profiles.suggest_available_handle(handle)
          updated_params = Map.put(user_params, "handle", suggested || handle)
          default_claim = status == :unclaimed
          {conflict, default_claim, suggested, updated_params}
        else
          # Re-detection: keep existing suggested handle, don't swap
          {conflict, false, current_suggested, user_params}
        end
    end
  end

  defp detect_handle_conflict(_handle, _current_conflict, _current_suggested, user_params) do
    {nil, false, nil, user_params}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
