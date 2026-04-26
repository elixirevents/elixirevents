import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/elixir_events start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :elixir_events, ElixirEventsWeb.Endpoint, server: true
end

config :elixir_events, ElixirEventsWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :elixir_events, ElixirEvents.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :elixir_events, ElixirEventsWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :elixir_events, ElixirEventsWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :elixir_events, ElixirEventsWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  config :elixir_events, ElixirEvents.Mailer,
    adapter: Swoosh.Adapters.Resend,
    api_key: System.get_env("RESEND_API_KEY"),
    from_email: System.get_env("MAILER_FROM_EMAIL", "noreply@elixirevents.org"),
    from_name: System.get_env("MAILER_FROM_NAME", "Elixir Events")

  config :open_api_typesense,
    api_key: System.fetch_env!("TYPESENSE_API_KEY"),
    host: System.fetch_env!("TYPESENSE_HOST"),
    port: String.to_integer(System.get_env("TYPESENSE_PORT", "443")),
    scheme: "https"

  config :elixir_events,
    typesense_search_key: System.fetch_env!("TYPESENSE_SEARCH_KEY"),
    typesense_search_host: System.fetch_env!("TYPESENSE_SEARCH_HOST")

  config :appsignal, :config,
    active: true,
    otp_app: :elixir_events,
    name: "elixir_events",
    push_api_key: System.fetch_env!("APPSIGNAL_PUSH_API_KEY")

  # Parse OBAN_QUEUES env var. Set per-role in config/deploy.yml so that
  # `web` containers don't process jobs (queues: false) and `workers`
  # containers do. Format: "default:5,search:5" or "none".
  #
  # Whitelist queue names to avoid atom exhaustion — only known queues
  # are accepted; unknown entries raise at boot.
  known_queues = %{"default" => :default, "search" => :search}

  oban_queues =
    case System.get_env("OBAN_QUEUES", "default:5,search:5") do
      "none" ->
        false

      str ->
        str
        |> String.split(",", trim: true)
        |> Enum.map(fn entry ->
          [name, limit] = String.split(entry, ":", parts: 2)

          atom =
            Map.get(known_queues, name) ||
              raise "Unknown OBAN_QUEUES entry: #{name}. Known: #{inspect(Map.keys(known_queues))}"

          {atom, String.to_integer(limit)}
        end)
    end

  config :elixir_events, Oban,
    repo: ElixirEvents.Repo,
    queues: oban_queues,
    plugins: [
      {Oban.Plugins.Cron,
       crontab: [
         {"0 1 * * *", ElixirEvents.Events.EventStatusWorker}
       ]}
    ]
end
