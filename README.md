# ElixirEvents

![ElixirEvents Banner](priv/static/images/elixirevents-banner.png)

Community directory for Elixir & BEAM conferences, talks, speakers, and topics.

Live at [elixirevents.org](https://elixirevents.org).

## Local Setup

Requirements: Elixir, Erlang, and PostgreSQL.

```bash
git clone https://github.com/elixirevents/elixirevents.git
cd elixirevents
mix setup
mix phx.server
```

Visit [localhost:4000](http://localhost:4000).

That's it. `mix setup` installs dependencies, creates the database, runs migrations, imports all YAML event data, and builds assets.

## Working with Data

All event data lives in `priv/data/` as YAML files. To add events, speakers, or talks, edit the YAML and open a PR. See the [contribute page](https://elixirevents.org/contribute) for details.

After editing YAML files, validate your changes:

```bash
mix elixir_events.validate
```

This checks YAML syntax, required fields, slug formats, duplicates, and cross-file references — no database needed. It runs in CI too, so catching issues locally saves a round-trip.

To re-import data after making YAML changes:

```bash
mix elixir_events.import
```

This is idempotent — safe to run multiple times. To start completely fresh, `mix ecto.reset` will drop the database, recreate it, and import everything.

You can also auto-fix common YAML issues (bad slugs, quoting problems):

```bash
mix elixir_events.data.fix        # apply fixes
mix elixir_events.data.fix --dry-run  # preview without changing files
```

## Search

Search is powered by [Typesense](https://typesense.org). Records are automatically synced to Typesense on every insert, update, and delete — including during deployment data imports. Under normal operation, no manual intervention is needed.

If search results get out of sync (e.g. after a failed deploy, manual database changes, or Typesense downtime), connect to the production console and trigger a reindex:

```bash
# Connect to the production IEx console
kamal app exec -i "/app/bin/elixir_events remote"
```

```elixir
# Reindex all collections
ElixirEvents.Search.reindex()

# Or reindex a specific collection
ElixirEvents.Search.reindex("events")
ElixirEvents.Search.reindex("talks")
ElixirEvents.Search.reindex("profiles")
ElixirEvents.Search.reindex("topics")
ElixirEvents.Search.reindex("event_series")
```

Reindex jobs run asynchronously via Oban.

## Production Deployment

The app runs on a single server managed by [Kamal 2](https://kamal-deploy.org). Cloudflare handles DNS and edge TLS. Kamal's proxy handles origin TLS (Let's Encrypt) and zero-downtime deploys.

### Stack

- **Hosting**: Hetzner Cloud (ARM)
- **Orchestration**: Kamal 2 (Docker-based)
- **Database**: PostgreSQL 17 (Kamal accessory, same server)
- **Search**: Typesense Cloud
- **Email**: Resend
- **Monitoring**: AppSignal
- **DNS/CDN**: Cloudflare
- **CI/CD**: GitHub Actions → Kamal deploy

### Setup

1. Update `config/deploy.yml` with your server details.
2. Create `.kamal/secrets` with your environment variables (see below).
3. Run `kamal setup` for first-time provisioning.

### Required Secrets

```
KAMAL_REGISTRY_USERNAME=
KAMAL_REGISTRY_PASSWORD=
SECRET_KEY_BASE=
DATABASE_URL=
POSTGRES_PASSWORD=
RESEND_API_KEY=
MAILER_FROM_EMAIL=
MAILER_FROM_NAME=
TYPESENSE_API_KEY=
TYPESENSE_HOST=
TYPESENSE_SEARCH_KEY=
TYPESENSE_SEARCH_HOST=
APPSIGNAL_PUSH_API_KEY=
DEPLOY_HOST=
DEPLOY_USER=
PHX_HOST=
```

Generate a secret key: `mix phx.gen.secret`

### Deploying

```bash
kamal setup    # First-time: installs Docker, boots accessories, deploys app
kamal deploy   # Subsequent deploys
```

Migrations and data sync run automatically on every deploy (via Dockerfile CMD).

### Remote Operations

```bash
kamal app exec -i "/app/bin/elixir_events remote"   # IEx console
kamal app logs                                        # View logs
kamal app exec "/app/bin/migrate"                     # Run migrations manually
```

### CI/CD

Pushes to `main` that pass all checks trigger an automatic deploy via GitHub Actions. The workflow writes `.kamal/secrets` from the `KAMAL_SECRETS` repository secret and deploys with Kamal.

Required GitHub Actions secrets: `DEPLOY_SSH_KEY`, `KAMAL_SECRETS`.

## Contributing

PRs welcome for data additions, bug fixes, tests, and code improvements. Run `mix test` and `mix elixir_events.validate` before submitting. See [CONTRIBUTING](https://elixirevents.org/contribute).

## Credits

Thank you [AppSignal](https://www.appsignal.com) for sponsoring application monitoring and error tracking for ElixirEvents.

Thank you [Typesense](https://typesense.org) for sponsoring a Typesense Cloud cluster that powers the search functionality.

## License

[MIT](LICENSE)
