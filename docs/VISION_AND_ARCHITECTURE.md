# ElixirEvents — Vision & High‑Level Architecture

ElixirEvents is a Phoenix (LiveView) application that curates upcoming and past Elixir/BEAM conferences, meetups, speakers, talks, and recordings. The goal is to be the canonical directory for events and content in the ecosystem, inspired by rubyevents.org but designed with idiomatic Elixir patterns and real‑time UX.

## Product Vision

- Source of truth for events, speakers, talks, and recordings across the BEAM ecosystem.
- Delightful, fast UI driven by Phoenix LiveView, optimized for discovery and curation.
- Community‑friendly submission flow with light moderation and optional GitHub syncing.
- Rich linking between entities (events ↔ talks ↔ speakers ↔ recordings) to enable exploration.
- High‑quality metadata for search, filters, feeds, and integrations (ICS, Atom/RSS, oEmbed).
- Initial scope: focus on conferences first; add meetups after core workflows and Oban ingestion are proven.

## Design Principles

- Phoenix‑native: LiveView first, streams for large lists, no client frameworks.
- Simple data model that maps to common conference lifecycles and community expectations.
- Moderation and trust: submissions are easy; publishing is controlled and auditable.
- Integrate, don’t scrape: use public APIs where possible via Req.
- Accessibility, performance, and polished micro‑interactions with Tailwind.

---

## Domain Model (High‑Level)

- Organization: group that runs events (e.g., a conference organizer or meetup group).
- Series: a recurring event brand (e.g., ElixirConf). An Organization may own many Series.
- Event: a single occurrence (e.g., ElixirConf EU 2026). Belongs to a Series (optional).
  - Attributes: name, slug, start_date, end_date, timezone, format (in‑person/virtual/hybrid), status (upcoming/past/cancelled), website, tickets_url, cfp_url, cfp_open/close_dates, description, social links.
  - Associations: venue (optional), schedules/sessions, talks, sponsors, media links, tags.
- Venue: physical location (name, city, country, coordinates) or virtual platform.
- Speaker: person profile with bio, socials, websites, avatar.
- Talk: a presentation associated with one or more Speakers; optionally linked to an Event.
  - Attributes: title, abstract, tags/topics, duration, language, level.
  - Associations: recordings, slides, links, event/session.
- Recording: a media item (YouTube/Vimeo/etc) for a Talk (or Event recap).
  - Attributes: provider, external_id, url, published_at, duration, view_count (optional sync), thumbnails.
- Session: scheduled unit within an Event (talks, workshops, keynotes, breaks). Optional if we only track accepted talks.
- Sponsor: organization sponsoring an Event with tier/level and logo/link.
- Tag: shared taxonomy across Events, Talks, and Speakers (topics, tech, region).
- Link: polymorphic links (slides, repos, blog posts, CFPs, playlists, programs).
- User: authenticated account (password authentication and GitHub OAuth from day one) for submissions and admin.
- Submission: proposed new or updated content (Event/Talk/Speaker) awaiting moderation.

Notes
- Slugs on public entities for stable URLs.
- Soft deletes for moderation (e.g., hide instead of destroy when appropriate).
- Timestamps and audit trail on changes (e.g., who approved what and when).

---

## Phoenix Contexts

Context boundaries should reflect business capabilities, not tables or technical layers. Treat each context as a public API for a slice of the domain. Prefer a small number of well‑named, cohesive contexts:

- Events: Event lifecycle and discovery
  - Entities: Series, Event, Venue, Schedule/Session, Sponsor, EventTags
  - Responsibilities: create/update/list/filter events; series management; venue data; sponsors; event tags; event ICS export
  - Integration hooks: Pretalx/Sessionize importers live under `Events.Importers.*`

- Speakers: People profiles
  - Entities: Speaker, SpeakerSocials
  - Responsibilities: create/update/list speakers; search by name/tags; profile claims

- Talks: Presentations and media
  - Entities: Talk, TalkSpeakers (M:N), Recording, TalkLinks (slides/repos)
  - Responsibilities: create/update/list talks; associate speakers; manage recordings and links; embed data enrichment
  - Service module (not a separate context): `Talks.Media` fetches oEmbed/provider metadata via Req

- Submissions: Community contribution + moderation
  - Entities: Submission, Review, Audit
  - Responsibilities: accept submissions (event/talk/speaker), diffing, approval workflow, audit trail

- Accounts: Authentication/authorization
  - Entities: User, Role (admin/moderator/contributor)
  - Responsibilities: sign‑in (password authentication via `phx.gen.auth` and GitHub OAuth via Assent from day one), roles/permissions, profiles

Notes and guidance
- Keep cross‑context knowledge at the boundaries: LiveViews and controllers call context APIs; contexts call each other sparingly and only through public functions.
- Avoid technical cross‑cutting contexts (e.g., a top‑level “Integrations”)—place importers/enrichers within the owning domain (`Events.Importers.*`, `Talks.Media`).
- Don’t mirror the database: contexts can own multiple schemas; schemas may move inside a context without changing the public API.
- Preloading belongs in context queries: when a template needs associations, expose functions that return the fully‑loaded structs required by the UI.

---

## LiveView Screens (Initial)

Public
- Home: spotlight upcoming events, featured recordings, search and filters.
- Events Index: filters by date range, region, format, tags; infinite scroll with streams.
- Event Show: details, schedule (optional), talks/recordings, venue map, sponsors.
- Speakers Index: list with search and facets (topic tags, region if available).
- Speaker Show: bio, talks, recordings, links.
- Talks Index: search by topic, event, speaker; list recordings first when available.
- Talk Show: abstract, speakers, event, recording(s), slides/links.
- Recordings Index: search/sort (date, popularity); YouTube/Vimeo embeds.
- Feeds: ICS for upcoming events; Atom/RSS for new recordings.

Submission & Moderation
- Submit Event: lightweight form; attachments/links; preview before submit.
- Submit Talk: associate with Event or standalone; add speakers.
- Submit Speaker: create/claim profile; verify via email/GitHub sign‑in.
- Moderation Queue: review diffs, approve/merge, comment back to submitter.
- Admin: manage taxonomies, featured content, bulk imports, background syncs.

Notes
- Use LiveView streams for list pages to keep memory usage low.
- Add explicit, unique DOM ids for key elements to aid testing.

---

## Data & Integrations (Req)

- YouTube/Vimeo
  - Resolve metadata for Recording via oEmbed when possible; fall back to provider APIs.
  - Optional scheduled sync job to refresh titles, thumbnails, durations, and views.
- CFPs
  - Read Pretalx/Sessionize event data to import accepted talks/schedules when available (place importers under `Events.Importers.*`).
- ICS
  - Export upcoming Events as ICS; optional import for community calendars.
- Social & Link Embeds
  - Normalize external links (slides, repos) and enrich using oEmbed where applicable.

All HTTP calls go through Req. Avoid introducing other HTTP clients. Place integration modules under the owning context rather than a global “Integrations” context.

---

## Submission Workflow

- Auth: GitHub OAuth for contributor sign‑in; anonymous allowed for basic event suggestions with email confirmation.
- Submissions create a draft in Curation.Submissions; admins/moderators approve.
- Optional GitHub Sync: mirror approved public data as JSON/YAML to a repo so the community can PR updates; keep the app database the primary store to enable great UX and moderation. If added, keep sync as a service called by `Events`, `Talks`, and `Speakers` rather than a top‑level context.
- Audit Trail: store diffs and approver for transparency.

Rationale vs rubyevents.org
- We prioritize an in‑app submission flow to reduce friction, while still enabling Git‑based contributions via export/sync for communities that prefer PRs.

---

## Moderation Audit & Transparency

- Policy: Tiered transparency — publish a minimal, safe audit publicly; keep full detail private for moderators.
- Public audit (always visible)
  - Fields: timestamp, action (created/updated/approved/rejected), high‑level diff of whitelisted fields, actor attribution as display name or "Community submission" (no email/IP).
  - Views: entity “History” section, site‑wide “Recent Changes” page, and Atom/JSON feed.
- Private audit (moderators only)
  - Full diffs, reviewer comments/reasons, PII (email/IP), spam flags/scores, and internal notes.
  - Full decision log with status transitions and escalations.
- Data model sketch
  - `Audit`: `actor_id`, `actor_role`, `resource_type/id`, `action`, `changes` (jsonb), `public_changes` (jsonb), `visibility` (:public|:private), `inserted_at`.
  - Compute `public_changes` at write time via a whitelist; ensure idempotent writes inside context functions using `Ecto.Multi`.
- Retention
  - Public audit: keep indefinitely.
  - Private audit: prune after ~18 months via an Oban pruning job.

---

## Storage & Background Work

- Database: PostgreSQL (default). All public entities get slugs and unique constraints.
- File storage: external avatars/logos via URLs; no local uploads initially.
- Background jobs: Use Oban from the start for async and scheduled work.
  - Queues: `:default` (low volume), `:media` (oEmbed/provider fetches), `:sync` (stats refresh), `:import` (Sessionize/Pretalx).
  - Plugins: `Oban.Plugins.Cron` (recurring jobs), `Oban.Plugins.Pruner` (cleanup).
  - Workers (examples): `Talks.Workers.MediaOEmbed`, `Talks.Workers.MediaRefresh`, `Events.Workers.SessionizeImport`, `Events.Workers.PretalxImport`.
  - Practices: retries with backoff, idempotency, `unique` to dedupe, per‑queue limits for back‑pressure.
  - Testing: use Oban’s testing helpers (inline/`assert_enqueued`/`perform_job`) and `start_supervised!/1`.
  - Use `Task.async_stream` only for small, non‑critical in‑request fan‑out.

---

## Routing & Auth (Sketch)

- Public routes: home, events, talks, speakers, recordings, feeds.
- Authenticated routes: submissions, profile, admin/moderation (LiveView sessions with `current_scope`).
- Always pass `current_scope` to `Layouts.app` to satisfy Phoenix 1.8 layout rules.
- Route LiveViews per context responsibility (e.g., `EventsLive.Index` uses `Events`, `SpeakersLive.Show` uses `Speakers`, `TalksLive.Show` uses `Talks`).

---

## Testing Approach (High‑Level)

- Use Phoenix.LiveViewTest and LazyHTML for UI assertions.
- Start processes with `start_supervised!/1`; avoid sleeps; monitor processes as needed.
- Prefer element presence and behavior over brittle text matching.
- Add isolated tests per screen (index/show) and per submission workflow step.

---

## UX Notes

- Consistent typography and spacing with Tailwind; refined hover and focus states.
- Use `<.icon>` component for icons; avoid external icon modules.
- Polished micro‑interactions: loading states, subtle transitions, optimistic UI where sensible.
- No inline scripts; use LiveView hooks (colocated or external) when needed.

---

## Internationalization (i18n)

- Recommendation: UI localization now; content translations later.
  - UI: use Gettext from day one for all interface strings; detect locale from `Accept-Language` and allow user preference.
  - Content: store a primary language per entity (`Event.language`, `Talk.language`, `Recording.language`); keep slugs language‑agnostic.
  - Formatting: keep date/time formatting simple and consistent; avoid extra i18n deps for now.
  - Phase 2: add translation tables (`EventTranslation`, `TalkTranslation`, `SpeakerTranslation`) and route prefixes per locale (e.g., `/pt/events`). Add `hreflang` when real translations exist.

---

## Initial Milestones

1) Skeleton
- Context modules for Events, Speakers, Talks, Submissions, Accounts.
- Schemas with minimal fields for Event, Speaker, Talk, Recording, Series, Venue, Tag.
- Oban setup: queues (`:default`, `:media`, `:sync`, `:import`) and plugins (Cron, Pruner).
- Routes + LiveViews: Home, Events Index/Show, Speakers Index/Show, Talks Show.

2) Submissions MVP
- GitHub OAuth; basic submission forms for Event and Talk; moderation queue.

3) Recordings
- Recording association to Talk; oEmbed fetch via Req; embed player on Talk pages; enqueue enrichment jobs through Oban.

4) Feeds & Discoverability
- ICS for upcoming events (via `Events.ics/1`); Atom for new recordings (via `Talks.atom/1`); simple sitemap.

5) Importers (Optional)
- Sessionize/Pretalx import via Oban workers; YouTube playlist importer for event channels.

6) Meetups Expansion
- Extend `Events` to support meetups: `event.kind` (e.g., `:conference | :meetup`), optional recurrence (RRULE), and “Group” via `Series`.
- Add `Events.Importers.ICS`/Luma Oban workers for meetup ingestion and deduping.
- Meetups index and group pages; separate ICS feed for meetups.

---

## Open Questions

- Scope decision: focus on conferences first; add meetups later once ingestion patterns are proven.
- Internationalization: proceed with UI i18n now (Gettext) and defer content translations to a later milestone as described above.
- Moderation audit: tiered transparency (public minimal audit; private full details) — decided.

---

## Next Steps For Implementation

- Generate core schemas and migrations; define slugs and uniqueness constraints.
- Build Events index/show with LiveView streams and preload patterns.
- Add Speakers and Talks with many‑to‑many for talk co‑authors; basic Recording embed.
- Implement submission flow and a simple moderation queue.
- Add ICS/Atom feeds and basic JSON endpoints for future integrations.
- Add Oban with initial queues/plugins and a first worker (`Talks.Workers.MediaOEmbed`) to enrich recordings.

This document is the living blueprint; we will refine it as we implement each area.
