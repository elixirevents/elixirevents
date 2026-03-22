defmodule ElixirEvents.OrganizationsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Organizations

  @valid_attrs %{
    name: "Fly.io",
    slug: "fly-io",
    website: "https://fly.io",
    logo_url: "https://fly.io/logo.svg"
  }

  describe "create_organization/1" do
    test "creates an org with valid attrs" do
      assert {:ok, org} = Organizations.create_organization(@valid_attrs)
      assert org.name == "Fly.io"
    end

    test "requires name and slug" do
      assert {:error, changeset} = Organizations.create_organization(%{})
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).slug
    end

    test "enforces unique slug" do
      {:ok, _} = Organizations.create_organization(@valid_attrs)
      assert {:error, changeset} = Organizations.create_organization(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "get_organization_by_slug/1" do
    test "returns org" do
      {:ok, org} = Organizations.create_organization(@valid_attrs)
      assert Organizations.get_organization_by_slug("fly-io").id == org.id
    end
  end

  describe "upsert_organization/1" do
    test "inserts a new org" do
      assert {:ok, org} = Organizations.upsert_organization(@valid_attrs)
      assert org.name == "Fly.io"
    end

    test "updates an existing org by slug" do
      {:ok, _} = Organizations.upsert_organization(@valid_attrs)
      {:ok, updated} = Organizations.upsert_organization(%{name: "Fly.io Inc", slug: "fly-io"})
      assert updated.name == "Fly.io Inc"
      assert [_only_one] = Organizations.list_organizations()
    end
  end
end
