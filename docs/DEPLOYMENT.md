# Deployment

The app runs on a single server managed by [Kamal 2](https://kamal-deploy.org). Cloudflare handles DNS and edge TLS. Kamal's proxy handles origin TLS (Let's Encrypt) and zero-downtime deploys.

## Stack

- **Hosting**: Hetzner Cloud (ARM)
- **Orchestration**: Kamal 2 (Docker-based)
- **Database**: PostgreSQL 17 (Kamal accessory, same server)
- **Search**: Typesense Cloud
- **Email**: Resend
- **Monitoring**: AppSignal
- **DNS/CDN**: Cloudflare
- **CI/CD**: GitHub Actions → Kamal deploy

## Setup

1. Update `config/deploy.yml` with your server details.
2. Create `.kamal/secrets` with your environment variables (see below).
3. Run `kamal setup` for first-time provisioning.

## Required Secrets

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

## Deploying

```bash
kamal setup    # First-time: installs Docker, boots accessories, deploys app
kamal deploy   # Subsequent deploys
```

Migrations and data sync run automatically on every deploy (via Dockerfile CMD).

## Remote Operations

```bash
kamal app exec -i "/app/bin/elixir_events remote"   # IEx console
kamal app logs                                        # View logs
kamal app exec "/app/bin/migrate"                     # Run migrations manually
```

## CI/CD

Pushes to `main` that pass all checks trigger an automatic deploy via GitHub Actions. The workflow writes `.kamal/secrets` from the `KAMAL_SECRETS` repository secret and deploys with Kamal.

Required GitHub Actions secrets: `DEPLOY_SSH_KEY`, `KAMAL_SECRETS`.
