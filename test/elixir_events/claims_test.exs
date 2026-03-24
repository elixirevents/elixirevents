defmodule ElixirEvents.ClaimsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Claims
  alias ElixirEvents.Claims.Claim
  alias ElixirEvents.Profiles

  import ElixirEvents.AccountsFixtures

  defp create_admin do
    user_fixture()
    |> Ecto.Changeset.change(role: :admin)
    |> Repo.update!()
  end

  defp create_profile(attrs \\ %{}) do
    {:ok, profile} =
      Profiles.create_profile(
        Map.merge(
          %{
            name: "Speaker #{System.unique_integer([:positive])}",
            handle: "speaker#{System.unique_integer([:positive])}"
          },
          attrs
        )
      )

    profile
  end

  describe "create_claim/3" do
    test "creates a pending claim" do
      user = user_fixture()
      profile = create_profile()

      assert {:ok, %Claim{} = claim} = Claims.create_claim(user, "profile", profile.id)
      assert claim.user_id == user.id
      assert claim.claimable_type == "profile"
      assert claim.claimable_id == profile.id
      assert claim.status == :pending
    end

    test "rejects duplicate claims" do
      user = user_fixture()
      profile = create_profile()

      assert {:ok, _claim} = Claims.create_claim(user, "profile", profile.id)
      assert {:error, changeset} = Claims.create_claim(user, "profile", profile.id)
      assert "has already been taken" in errors_on(changeset).user_id
    end

    test "accepts user_notes" do
      user = user_fixture()
      profile = create_profile()

      assert {:ok, claim} =
               Claims.create_claim(user, "profile", profile.id, %{user_notes: "This is me"})

      assert claim.user_notes == "This is me"
    end

    test "rejects user_notes longer than 1000 characters" do
      user = user_fixture()
      profile = create_profile()
      long_notes = String.duplicate("a", 1001)

      assert {:error, changeset} =
               Claims.create_claim(user, "profile", profile.id, %{user_notes: long_notes})

      assert "should be at most 1000 character(s)" in errors_on(changeset).user_notes
    end
  end

  describe "approve_claim/2" do
    test "approves a pending claim" do
      user = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      assert {:ok, approved} = Claims.approve_claim(claim, admin)

      assert approved.status == :approved
      assert approved.reviewed_by_id == admin.id
      assert approved.reviewed_at != nil
    end

    test "rejects if email not confirmed" do
      user = unconfirmed_user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      assert {:error, :email_not_confirmed} = Claims.approve_claim(claim, admin)
    end

    test "revokes previous approved claim on same entity" do
      user1 = user_fixture()
      user2 = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim1} = Claims.create_claim(user1, "profile", profile.id)
      {:ok, _approved1} = Claims.approve_claim(claim1, admin)

      {:ok, claim2} = Claims.create_claim(user2, "profile", profile.id)
      {:ok, _approved2} = Claims.approve_claim(claim2, admin)

      # First claim should now be revoked
      revoked = Repo.get!(Claim, claim1.id)
      assert revoked.status == :revoked
    end

    test "sets user_id on claimed profile and deletes registration profile" do
      user = user_fixture()
      admin = create_admin()

      # user_fixture creates a registration profile
      registration_profile = Profiles.get_profile_for_user(user.id)
      assert registration_profile != nil

      # Create a separate profile to claim
      claimed_profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", claimed_profile.id)
      {:ok, _approved} = Claims.approve_claim(claim, admin)

      # Registration profile should be deleted
      assert Profiles.get_profile(registration_profile.id) == nil

      # Claimed profile should now belong to user
      updated_profile = Profiles.get_profile(claimed_profile.id)
      assert updated_profile.user_id == user.id
    end
  end

  describe "claimed_by?/3" do
    test "returns true for approved claim" do
      user = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      {:ok, _approved} = Claims.approve_claim(claim, admin)

      assert Claims.claimed_by?(user, "profile", profile.id) == true
    end

    test "returns false for pending claim" do
      user = user_fixture()
      profile = create_profile()

      {:ok, _claim} = Claims.create_claim(user, "profile", profile.id)

      assert Claims.claimed_by?(user, "profile", profile.id) == false
    end
  end

  describe "reject_claim/3" do
    test "sets status to rejected and admin_notes" do
      user = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      assert {:ok, rejected} = Claims.reject_claim(claim, admin, "Not enough evidence")

      assert rejected.status == :rejected
      assert rejected.admin_notes == "Not enough evidence"
      assert rejected.reviewed_by_id == admin.id
      assert rejected.reviewed_at != nil
    end
  end

  describe "claimed?/2" do
    test "returns true when an approved claim exists" do
      user = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      {:ok, _approved} = Claims.approve_claim(claim, admin)

      assert Claims.claimed?("profile", profile.id) == true
    end

    test "returns false when no approved claim exists" do
      user = user_fixture()
      profile = create_profile()

      {:ok, _claim} = Claims.create_claim(user, "profile", profile.id)

      assert Claims.claimed?("profile", profile.id) == false
    end
  end

  describe "list_pending_claims/0" do
    test "returns only pending claims" do
      user1 = user_fixture()
      user2 = user_fixture()
      admin = create_admin()
      profile1 = create_profile()
      profile2 = create_profile()

      {:ok, _claim1} = Claims.create_claim(user1, "profile", profile1.id)
      {:ok, claim2} = Claims.create_claim(user2, "profile", profile2.id)
      {:ok, _approved} = Claims.approve_claim(claim2, admin)

      pending = Claims.list_pending_claims()
      assert length(pending) == 1
      assert hd(pending).claimable_id == profile1.id
    end
  end

  describe "revoke_claim/1" do
    test "sets claim status to revoked" do
      user = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      {:ok, approved} = Claims.approve_claim(claim, admin)
      assert {:ok, revoked} = Claims.revoke_claim(approved)
      assert revoked.status == :revoked
    end
  end

  describe "list_claims/1" do
    test "returns all claims ordered by inserted_at desc" do
      user1 = user_fixture()
      user2 = user_fixture()
      profile1 = create_profile()
      profile2 = create_profile()

      {:ok, _} = Claims.create_claim(user1, "profile", profile1.id)
      {:ok, _} = Claims.create_claim(user2, "profile", profile2.id)

      claims = Claims.list_claims()
      assert length(claims) == 2
    end

    test "filters by status" do
      user1 = user_fixture()
      user2 = user_fixture()
      admin = create_admin()
      profile1 = create_profile()
      profile2 = create_profile()

      {:ok, _} = Claims.create_claim(user1, "profile", profile1.id)
      {:ok, claim2} = Claims.create_claim(user2, "profile", profile2.id)
      {:ok, _} = Claims.approve_claim(claim2, admin)

      assert [%{status: :approved}] = Claims.list_claims(status: :approved)
      assert [%{status: :pending}] = Claims.list_claims(status: :pending)
    end
  end

  describe "get_claim!/1" do
    test "returns the claim with preloaded associations" do
      user = user_fixture()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      found = Claims.get_claim!(claim.id)
      assert found.id == claim.id
      assert found.user.id == user.id
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Claims.get_claim!(0)
      end
    end
  end

  describe "get_approved_claim/2" do
    test "returns the approved claim for an entity" do
      user = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      {:ok, _} = Claims.approve_claim(claim, admin)

      found = Claims.get_approved_claim("profile", profile.id)
      assert found.id == claim.id
    end

    test "returns nil when no approved claim exists" do
      assert Claims.get_approved_claim("profile", 0) == nil
    end
  end

  describe "has_active_claim?/2" do
    test "returns true when user has a pending claim" do
      user = user_fixture()
      profile = create_profile()
      {:ok, _} = Claims.create_claim(user, "profile", profile.id)

      assert Claims.has_active_claim?(user, "profile") == true
    end

    test "returns true when user has an approved claim" do
      user = user_fixture()
      admin = create_admin()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      {:ok, _} = Claims.approve_claim(claim, admin)

      assert Claims.has_active_claim?(user, "profile") == true
    end

    test "returns false when user has no claims" do
      user = user_fixture()
      assert Claims.has_active_claim?(user, "profile") == false
    end
  end

  describe "get_user_claim/3" do
    test "returns the user's claim for the entity" do
      user = user_fixture()
      profile = create_profile()

      {:ok, claim} = Claims.create_claim(user, "profile", profile.id)
      found = Claims.get_user_claim(user, "profile", profile.id)

      assert found.id == claim.id
    end

    test "returns nil when no claim exists" do
      user = user_fixture()
      assert Claims.get_user_claim(user, "profile", 999_999) == nil
    end
  end
end
