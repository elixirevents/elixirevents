import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :elixir_events, ElixirEvents.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "elixir_events_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elixir_events, ElixirEventsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "VtnMfSKL3pMU4Q+DmpG7hCBiZc9WAH4ZBYqlOBz0+llgr3rp/OXOi3CICKPV/hYj",
  server: false

# In test we don't send emails
config :elixir_events, ElixirEvents.Mailer,
  adapter: Swoosh.Adapters.Test,
  from_email: "noreply@elixirevents.org",
  from_name: "Elixir Events"

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :elixir_events, Oban, testing: :manual

config :open_api_typesense,
  api_key: "test_typesense_api_key",
  host: "localhost",
  port: 8108,
  scheme: "http"

config :elixir_events,
  typesense_search_key: "test_typesense_api_key",
  typesense_search_host: "http://localhost:8108"
