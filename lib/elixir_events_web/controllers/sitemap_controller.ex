defmodule ElixirEventsWeb.SitemapController do
  use ElixirEventsWeb, :controller

  alias ElixirEvents.{Events, Profiles, Talks, Topics}
  alias ElixirEventsWeb.SEO

  def index(conn, _params) do
    events = Events.list_events([])
    talks = Talks.list_talks(preload: [:event])
    profiles = Profiles.list_profiles(speakers_only: true)
    topics = Topics.list_topics([])
    series = Events.list_event_series()

    urls =
      static_urls() ++
        event_urls(events) ++
        talk_urls(talks) ++
        profile_urls(profiles) ++
        topic_urls(topics) ++
        series_urls(series)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, render_sitemap(urls))
  end

  defp static_urls do
    base = SEO.base_url()

    [
      %{loc: base, changefreq: "daily", priority: "1.0"},
      %{loc: "#{base}/events", changefreq: "daily", priority: "0.9"},
      %{loc: "#{base}/talks", changefreq: "daily", priority: "0.8"},
      %{loc: "#{base}/speakers", changefreq: "weekly", priority: "0.7"},
      %{loc: "#{base}/topics", changefreq: "weekly", priority: "0.7"},
      %{loc: "#{base}/about", changefreq: "monthly", priority: "0.4"},
      %{loc: "#{base}/contribute", changefreq: "monthly", priority: "0.4"}
    ]
  end

  defp event_urls(events) do
    base = SEO.base_url()

    Enum.map(events, fn event ->
      %{
        loc: "#{base}/events/#{event.slug}",
        lastmod: to_date(event.updated_at),
        changefreq: "weekly",
        priority: "0.8"
      }
    end)
  end

  defp talk_urls(talks) do
    base = SEO.base_url()

    Enum.map(talks, fn talk ->
      %{
        loc: "#{base}/talks/#{talk.event.slug}/#{talk.slug}",
        lastmod: to_date(talk.updated_at),
        changefreq: "monthly",
        priority: "0.6"
      }
    end)
  end

  defp profile_urls(profiles) do
    base = SEO.base_url()

    Enum.map(profiles, fn profile ->
      %{
        loc: "#{base}/profiles/#{profile.handle}",
        lastmod: to_date(profile.updated_at),
        changefreq: "monthly",
        priority: "0.5"
      }
    end)
  end

  defp topic_urls(topics) do
    base = SEO.base_url()

    Enum.map(topics, fn topic ->
      %{
        loc: "#{base}/topics/#{topic.slug}",
        lastmod: to_date(topic.updated_at),
        changefreq: "weekly",
        priority: "0.5"
      }
    end)
  end

  defp series_urls(series) do
    base = SEO.base_url()

    Enum.map(series, fn s ->
      %{
        loc: "#{base}/series/#{s.slug}",
        lastmod: to_date(s.updated_at),
        changefreq: "monthly",
        priority: "0.5"
      }
    end)
  end

  defp render_sitemap(urls) do
    entries =
      Enum.map_join(urls, "\n", fn url ->
        lastmod =
          if url[:lastmod],
            do: "\n    <lastmod>#{url.lastmod}</lastmod>",
            else: ""

        """
          <url>
            <loc>#{escape(url.loc)}</loc>#{lastmod}
            <changefreq>#{url.changefreq}</changefreq>
            <priority>#{url.priority}</priority>
          </url>\
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{entries}
    </urlset>
    """
  end

  defp escape(str), do: str |> String.replace("&", "&amp;")

  defp to_date(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_date(ndt) |> Date.to_iso8601()
  defp to_date(%DateTime{} = dt), do: DateTime.to_date(dt) |> Date.to_iso8601()
  defp to_date(%Date{} = d), do: Date.to_iso8601(d)
  defp to_date(_), do: nil
end
