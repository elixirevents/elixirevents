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

`mix setup` handles deps, database creation, migrations, seeds, and asset builds.

## Data

All event data lives in `priv/data/` as YAML files. To add events, speakers, or talks, edit the YAML and open a PR. See the [contribute page](https://elixirevents.org/contribute) for details.

## Contributing

PRs welcome for data additions, bug fixes, tests, and code improvements. See [CONTRIBUTING](https://elixirevents.org/contribute).

## License

[MIT](LICENSE)
