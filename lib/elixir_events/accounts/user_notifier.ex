defmodule ElixirEvents.Accounts.UserNotifier do
  @moduledoc false

  import Swoosh.Email

  alias ElixirEvents.Mailer

  defp mailer_config(key) do
    Application.get_env(:elixir_events, ElixirEvents.Mailer)[key]
  end

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({mailer_config(:from_name), mailer_config(:from_email)})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver confirmation instructions to the given user.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver claim approved notification.
  """
  def deliver_claim_approved(user, profile) do
    deliver(user.email, "Your profile claim has been approved", """

    ==============================

    Hi #{user.email},

    Great news — your claim for the speaker profile "#{profile.name}" has been approved!
    Your accounts have been merged and you can now edit your speaker profile.

    ==============================
    """)
  end

  @doc """
  Deliver claim rejected notification.
  """
  def deliver_claim_rejected(user, profile, admin_notes) do
    notes_section =
      if admin_notes do
        """

        Reviewer notes: #{admin_notes}
        """
      else
        ""
      end

    deliver(user.email, "Update on your profile claim", """

    ==============================

    Hi #{user.email},

    Unfortunately, your claim for the speaker profile "#{profile.name}" wasn't approved.
    #{notes_section}
    If you believe this is an error, please reach out to us.

    ==============================
    """)
  end
end
