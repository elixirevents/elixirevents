defmodule ElixirEvents.ProfilesTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Profiles

  @valid_attrs %{
    name: "Jose Valim",
    handle: "josevalim",
    bio: "Creator of Elixir",
    website: "https://dashbit.co"
  }

  describe "create_profile/1" do
    test "creates a profile with valid attrs" do
      assert {:ok, profile} = Profiles.create_profile(@valid_attrs)
      assert profile.name == "Jose Valim"
      assert profile.handle == "josevalim"
    end

    test "requires name and handle" do
      assert {:error, changeset} = Profiles.create_profile(%{})
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).handle
    end

    test "supports social_links embed" do
      attrs =
        Map.put(@valid_attrs, :social_links, [
          %{platform: :github, url: "https://github.com/josevalim"}
        ])

      assert {:ok, profile} = Profiles.create_profile(attrs)
      assert [%{platform: :github}] = profile.social_links
    end

    test "enforces unique handle" do
      {:ok, _} = Profiles.create_profile(@valid_attrs)
      assert {:error, changeset} = Profiles.create_profile(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).handle
    end
  end

  describe "list_profiles/0" do
    test "returns all profiles" do
      {:ok, profile} = Profiles.create_profile(@valid_attrs)
      assert [found] = Profiles.list_profiles()
      assert found.id == profile.id
    end
  end

  describe "get_profile_by_handle/1" do
    test "returns profile" do
      {:ok, profile} = Profiles.create_profile(@valid_attrs)
      assert Profiles.get_profile_by_handle("josevalim").id == profile.id
    end
  end

  describe "list_profiles/1 with options" do
    test "filters with talk count and ordering" do
      {:ok, _} = Profiles.create_profile(@valid_attrs)
      results = Profiles.list_profiles(with_talk_count: true, order_by: :name_asc)
      assert [%{name: "Jose Valim"}] = results
    end

    test "limits results" do
      {:ok, _} = Profiles.create_profile(@valid_attrs)
      {:ok, _} = Profiles.create_profile(%{name: "Chris McCord", handle: "chrismccord"})
      assert [_] = Profiles.list_profiles(limit: 1)
    end
  end

  describe "paginate_profiles/1" do
    test "returns paginated results" do
      {:ok, _} = Profiles.create_profile(@valid_attrs)
      page = Profiles.paginate_profiles(per_page: 1)
      assert [%{name: "Jose Valim"}] = page.entries
      assert page.total_count == 1
    end
  end

  describe "count_profiles/0" do
    test "returns the number of profiles" do
      assert Profiles.count_profiles() == 0
      {:ok, _} = Profiles.create_profile(@valid_attrs)
      assert Profiles.count_profiles() == 1
    end
  end

  describe "get_profile/1" do
    test "returns a profile by id" do
      {:ok, profile} = Profiles.create_profile(@valid_attrs)
      assert Profiles.get_profile(profile.id).handle == "josevalim"
    end

    test "returns nil for non-existent id" do
      assert Profiles.get_profile(0) == nil
    end
  end

  describe "get_profile_by_handle!/1" do
    test "returns the profile" do
      {:ok, profile} = Profiles.create_profile(@valid_attrs)
      assert Profiles.get_profile_by_handle!("josevalim").id == profile.id
    end

    test "raises for non-existent handle" do
      assert_raise Ecto.NoResultsError, fn ->
        Profiles.get_profile_by_handle!("nonexistent")
      end
    end
  end

  describe "update_profile/2" do
    test "updates a profile with valid attrs" do
      {:ok, profile} = Profiles.create_profile(@valid_attrs)
      assert {:ok, updated} = Profiles.update_profile(profile, %{bio: "Updated bio"})
      assert updated.bio == "Updated bio"
    end
  end

  describe "update_profile_as_owner/2" do
    test "allows updating owner-editable fields" do
      {:ok, profile} = Profiles.create_profile(@valid_attrs)

      assert {:ok, updated} =
               Profiles.update_profile_as_owner(profile, %{
                 headline: "Elixir creator",
                 bio: "New bio"
               })

      assert updated.headline == "Elixir creator"
      assert updated.bio == "New bio"
    end
  end

  describe "get_profile_for_user/1 and create_profile_for_user/2" do
    import ElixirEvents.AccountsFixtures

    test "creates and retrieves a profile for a user" do
      user = user_fixture()
      # user_fixture creates a profile via registration, so get that first
      existing = Profiles.get_profile_for_user(user.id)
      assert existing != nil

      # Verify get_profile_for_user returns the right profile
      assert existing.user_id == user.id
    end
  end

  describe "get_profile_by_handle_with_owner_status/1" do
    import ElixirEvents.AccountsFixtures

    test "returns {:unclaimed, profile} for profile with no user_id" do
      {:ok, profile} = Profiles.create_profile(@valid_attrs)
      assert {:unclaimed, found} = Profiles.get_profile_by_handle_with_owner_status("josevalim")
      assert found.id == profile.id
    end

    test "returns {:claimed, profile} for profile with user_id" do
      user = user_fixture()
      profile = Profiles.get_profile_for_user(user.id)
      assert {:claimed, found} = Profiles.get_profile_by_handle_with_owner_status(profile.handle)
      assert found.id == profile.id
    end

    test "returns nil for nonexistent handle" do
      assert Profiles.get_profile_by_handle_with_owner_status("nonexistent") == nil
    end
  end

  describe "suggest_available_handle/1" do
    test "returns handle with suffix 1 when base handle is taken" do
      {:ok, _} = Profiles.create_profile(%{name: "Test", handle: "taken"})
      assert Profiles.suggest_available_handle("taken") == "taken1"
    end

    test "increments suffix when lower suffixes are taken" do
      {:ok, _} = Profiles.create_profile(%{name: "Test 1", handle: "taken"})
      {:ok, _} = Profiles.create_profile(%{name: "Test 2", handle: "taken1"})
      assert Profiles.suggest_available_handle("taken") == "taken2"
    end

    test "returns nil when all 10 suffixes are taken" do
      {:ok, _} = Profiles.create_profile(%{name: "Base", handle: "taken"})

      for i <- 1..10 do
        {:ok, _} = Profiles.create_profile(%{name: "Test #{i}", handle: "taken#{i}"})
      end

      assert Profiles.suggest_available_handle("taken") == nil
    end

    test "returns the handle itself if it is available" do
      assert Profiles.suggest_available_handle("available") == "available"
    end
  end

  describe "upsert_profile/1" do
    test "inserts a new profile" do
      assert {:ok, profile} = Profiles.upsert_profile(@valid_attrs)
      assert profile.name == "Jose Valim"
    end

    test "updates an existing profile by handle" do
      {:ok, _} = Profiles.upsert_profile(@valid_attrs)

      {:ok, updated} =
        Profiles.upsert_profile(%{
          name: "Jose Valim",
          handle: "josevalim",
          bio: "Updated bio",
          social_links: [%{platform: :github, url: "https://github.com/josevalim"}]
        })

      assert updated.bio == "Updated bio"
      assert [_only_one] = Profiles.list_profiles()
    end
  end
end
