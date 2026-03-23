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

## Contributing

PRs welcome for data additions, bug fixes, tests, and code improvements. Run `mix test` and `mix elixir_events.validate` before submitting. See [CONTRIBUTING](https://elixirevents.org/contribute).

## License

[MIT](LICENSE)
