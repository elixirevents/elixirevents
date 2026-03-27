defmodule ElixirEventsWeb.Router do
  use ElixirEventsWeb, :router

  import ElixirEventsWeb.UserAuth
  import Lotus.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElixirEventsWeb.Layouts, :root}
    plug :put_layout, html: {ElixirEventsWeb.Layouts, :app}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "strict-transport-security" => "max-age=63072000; includeSubDomains; preload"
    }

    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElixirEventsWeb do
    get "/sitemap.xml", SitemapController, :index
  end

  scope "/", ElixirEventsWeb do
    pipe_through :browser

    live_session :default,
      layout: {ElixirEventsWeb.Layouts, :app},
      on_mount: [{ElixirEventsWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive, :index
      live "/about", AboutLive, :index
      live "/contribute", ContributeLive, :index
      live "/events", EventLive.Index, :index
      live "/events/:slug", EventLive.Show, :show
      live "/events/:slug/talks", EventLive.Talks, :index
      live "/events/:slug/schedule", EventLive.Schedule, :index
      live "/events/:slug/speakers", EventLive.Speakers, :index
      live "/series/:slug", SeriesLive.Show, :show
      live "/speakers", SpeakerLive.Index, :index
      live "/profiles/:handle", ProfileLive.Show, :show
      live "/talks", TalkLive.Index, :index
      live "/talks/:event_slug/:slug", TalkLive.Show, :show
      live "/events/:event_slug/workshops/:slug", WorkshopLive.Show, :show
      live "/topics", TopicLive.Index, :index
      live "/topics/:slug", TopicLive.Show, :show
    end
  end

  # Admin routes — requires authentication + admin role.
  scope "/admin", ElixirEventsWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin,
      layout: {ElixirEventsWeb.Layouts, :admin},
      on_mount: [
        {ElixirEventsWeb.UserAuth, :require_authenticated},
        {ElixirEventsWeb.Plugs.AdminAuth, :ensure_admin_authenticated},
        {ElixirEventsWeb.Plugs.AdminAuth, :assign_admin_path}
      ] do
      live "/claims", ClaimLive.Index, :index
      live "/claims/:id", ClaimLive.Show, :show
    end
  end

  scope "/admin" do
    pipe_through [:browser, :require_authenticated_user]

    lotus_dashboard("/lotus",
      resolver: ElixirEventsWeb.LotusResolver,
      on_mount: [{ElixirEventsWeb.UserAuth, :mount_current_scope}]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElixirEventsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:elixir_events, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElixirEventsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ElixirEventsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      layout: {ElixirEventsWeb.Layouts, :app},
      on_mount: [{ElixirEventsWeb.UserAuth, :require_authenticated}] do
      live "/account/security", UserLive.Settings, :edit
      live "/account/security/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/account/profile", ProfileLive.Edit, :edit
    end

    post "/account/security/update-password", UserSessionController, :update_password
  end

  scope "/", ElixirEventsWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ElixirEventsWeb.UserAuth, :mount_current_scope}] do
      live "/join", UserLive.Registration, :new
      live "/login", UserLive.Login, :new
    end

    post "/login", UserSessionController, :create
    get "/confirm/:token", UserSessionController, :confirm
    delete "/logout", UserSessionController, :delete
  end
end
