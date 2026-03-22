This is a web application written using the Phoenix web framework.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

### JS and CSS guidelines

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates**

### UI/UX & design guidelines

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions


<!-- phoenix-gen-auth-start -->
## Authentication

- **Always** handle authentication flow at the router level with proper redirects
- **Always** be mindful of where to place routes. `phx.gen.auth` creates multiple router plugs and `live_session` scopes:
  - A plug `:fetch_current_scope_for_user` that is included in the default browser pipeline
  - A plug `:require_authenticated_user` that redirects to the log in page when the user is not authenticated
  - A `live_session :current_user` scope - for routes that need the current user but don't require authentication, similar to `:fetch_current_scope_for_user`
  - A `live_session :require_authenticated_user` scope - for routes that require authentication, similar to the plug with the same name
  - In both cases, a `@current_scope` is assigned to the Plug connection and LiveView socket
  - A plug `redirect_if_user_is_authenticated` that redirects to a default path in case the user is authenticated - useful for a registration page that should only be shown to unauthenticated users
- **Always let the user know in which router scopes, `live_session`, and pipeline you are placing the route, AND SAY WHY**
- `phx.gen.auth` assigns the `current_scope` assign - it **does not assign a `current_user` assign**
- Always pass the assign `current_scope` to context modules as first argument. When performing queries, use `current_scope.user` to filter the query results
- To derive/access `current_user` in templates, **always use the `@current_scope.user`**, never use **`@current_user`** in templates or LiveViews
- **Never** duplicate `live_session` names. A `live_session :current_user` can only be defined __once__ in the router, so all routes for the `live_session :current_user`  must be grouped in a single block
- Anytime you hit `current_scope` errors or the logged in session isn't displaying the right content, **always double check the router and ensure you are using the correct plug and `live_session` as described below**

### Routes that require authentication

LiveViews that require login should **always be placed inside the __existing__ `live_session :require_authenticated_user` block**:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{ElixirEventsWeb.UserAuth, :require_authenticated}] do
        # phx.gen.auth generated routes
        live "/users/settings", UserLive.Settings, :edit
        live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
        # our own routes that require logged in user
        live "/", MyLiveThatRequiresAuth, :index
      end
    end

Controller routes must be placed in a scope that sets the `:require_authenticated_user` plug:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      get "/", MyControllerThatRequiresAuth, :index
    end

### Routes that work with or without authentication

LiveViews that can work with or without authentication, **always use the __existing__ `:current_user` scope**, ie:

    scope "/", MyAppWeb do
      pipe_through [:browser]

      live_session :current_user,
        on_mount: [{ElixirEventsWeb.UserAuth, :mount_current_scope}] do
        # our own routes that work with or without authentication
        live "/", PublicLive
      end
    end

Controllers automatically have the `current_scope` available if they use the `:browser` pipeline.

<!-- phoenix-gen-auth-end -->

<!-- usage-rules-start -->

<!-- phoenix:architecture-start -->
## Architecture & Libraries

- Prefer a single app (non‑umbrella) unless there is a hard boundary that requires separate deploy/release lifecycles.
- Organize code by Phoenix contexts that reflect business capabilities (e.g., `Accounts`, `Events`, `Billing`). Contexts expose a small, clear API; do not leak schemas or Repo details across contexts.
- Keep boundary modules thin and explicit: functions accept/return plain structs and maps; avoid returning changesets from context APIs except when the caller is a form.
- Use behaviours to model integration boundaries (email, payments, analytics). Provide a prod adapter and validate integrations in tests with `Mimic` or dedicated test adapters.
- Schema base macro: provide a `Schema` helper to standardize UTC microsecond timestamps and imports. Default to integer primary keys for this project.
- Context event modules: for each context that emits domain events, add a small `Events` submodule that defines typed structs (e.g., `%Accounts.Events.ActiveProfileChanged{...}`). Broadcast events from the context as `{ContextModule, event_struct}` over PubSub.
- PubSub helpers: keep an `@pubsub` constant and `topic(id)` helpers per context for `subscribe/1`, `unsubscribe/1`, and `broadcast!/2` wrappers.
 - Caching (when justified): prefer supervised ETS caches with explicit TTL and invalidation. For hot caches under concurrency, use a partitioned cache (e.g., ConCache with N partitions) and provide warmers to refresh entries on intervals.
- Prefer processes for ongoing, stateful workflows only. For one‑off async work, use jobs (Oban) instead of bespoke GenServers.
- Use Phoenix PubSub + LiveView to broadcast domain changes to the UI. Keep broadcast payloads minimal (ids); refetch in subscribers when needed.

### Preferred libraries

- HTTP client: `Req` (backed by Finch). Centralize configuration in one module (timeouts, base_url, auth), use `Req.new/1` pipelines and `Req.request!/1` for strict call sites.
- Jobs: `Oban` for background/scheduled work and retries. Keep job args minimal; fetch state in `perform/1`.

- Auth crypto: `bcrypt_elixir` (or `argon2_elixir`) via `phx.gen.auth` patterns.
 - OAuth: GitHub OAuth via `assent` from day one; keep password auth as well. Use `on_mount` hooks to assign `@current_user` uniformly across flows.
- JSON: `JSON` (Elixir's built‑in). Prefer returning plain maps from contexts or minimal, explicit encoders only where required.
- Pagination: use `paginator` (cursor-based) for large datasets and stable ordering.
- Testing: `Mimic` (module/function mocking where appropriate), `ExUnitProperties` (when property tests help), `Floki` (HTML assertions when necessary) but prefer `Phoenix.LiveViewTest` selectors.
- Telemetry/Tracing: `:telemetry`, `opentelemetry_*` (if tracing is enabled), `Telemetry.Metrics` or `:prom_ex` for metrics.

### Libraries to avoid (unless justified)

- Multiple HTTP clients. Standardize on `Req`. Avoid `HTTPoison`, `Tesla`, `httpc`.
- Ad‑hoc job queues or custom retry logic. Use `Oban`.
- Global state via ETS as a cache without invalidation strategy. Prefer explicit caches (e.g., a supervised ETS with clear ownership) or database queries with indexes.
<!-- phoenix:architecture-end -->

<!-- phoenix:elixir-start -->
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

## Test guidelines

- **Always use `start_supervised!/1`** to start processes in tests as it guarantees cleanup between tests
- **Avoid** `Process.sleep/1` and `Process.alive?/1` in tests
  - Instead of sleeping to wait for a process to finish, **always** use `Process.monitor/1` and assert on the DOWN message:

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

   - Instead of sleeping to synchronize before the next call, **always** use `_ = :sys.get_state/1` to ensure the process has handled prior messages
<!-- phoenix:elixir-end -->

<!-- phoenix:phoenix-start -->
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
<!-- phoenix:phoenix-end -->

<!-- phoenix:ecto-start -->
## Ecto Guidelines

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`
- `Ecto.Schema` fields always use the `:string` type, even for `:text`, columns, ie: `field :name, :string`
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such as option is never needed
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct
- **Always** invoke `mix ecto.gen.migration migration_name_using_underscores` when generating migration files, so the correct timestamp and conventions are applied
<!-- phoenix:ecto-end -->

<!-- phoenix:ecto-advanced-start -->
## Ecto — Advanced practices

- Model constraints in the database first (unique, foreign keys, check constraints) and mirror them in changesets with `unique_constraint/3`, `foreign_key_constraint/3`, and `check_constraint/3` for human‑friendly errors.
- Add covering/composite indexes for frequent filters and sorts. Prefer deterministic indexes over application‑level caching for consistency.
- Use `insert_all`/`update_all` sparingly and only for bulk ops that don’t require changeset validation.
- Wrap multi‑record workflows in `Ecto.Multi` and return a single, typed result per context function.
- Keep migrations reversible; avoid data migrations in schema migrations. Place long‑running data fixes in separate, idempotent operations (e.g., tasks or Oban jobs).
- Prefer `Repo.stream/2` with transactions for large exports; never load unbounded result sets into memory.
- Soft deletes: use `ecto_soft_delete` for user-owned content where retention/recovery is needed; document which tables use soft delete.
- Migration linting: enable `excellent_migrations` in dev/test to catch dangerous changes early.
<!-- phoenix:ecto-advanced-end -->

<!-- phoenix:html-start -->
## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- For "app wide" template imports, you can import/alias into the `my_app_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponent's, and all modules that do `use MyAppWeb, :html` (replace "my_app" by the actual app name)

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`**. **Never use `else if` or `elseif` in Elixir**, **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes, **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`)

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>
<!-- phoenix:html-end -->

<!-- phoenix:liveview-start -->
## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and  `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`
- Auth hooks: use `on_mount` hooks like `:current_user` and `:ensure_authenticated` to assign `@current_user` and guard access in LiveViews. Use `assign_new/3` within hooks to load users only once per socket.

### LiveView streams

- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- LiveView streams are *not* enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # re-fetch the messages based on the filter
        messages = list_messages(filter)

        {:noreply,
         socket
         |> assign(:messages_empty?, messages == [])
         # reset the stream with the new messages
         |> stream(:messages, messages, reset: true)}
      end

- LiveView streams *do not support counting or empty states*. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @stream.tasks} id={id}>
          {task.name}
        </div>
      </div>

  The above only works if the empty state is the only HTML block alongside the stream for-comprehension.

- When updating an assign that should change content inside any streamed item(s), you MUST re-stream the items
  along with the updated assign:

      def handle_event("edit_message", %{"message_id" => message_id}, socket) do
        message = Chat.get_message!(message_id)
        edit_form = to_form(Chat.change_message(message, %{content: message.content}))

        # re-insert message so @editing_message_id toggle logic takes effect for that stream item
        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign(:editing_message_id, String.to_integer(message_id))
         |> assign(:edit_form, edit_form)}
      end

  And in the template:

      <div id="messages" phx-update="stream">
        <div :for={{id, message} <- @streams.messages} id={id} class="flex group">
          {message.username}
          <%= if @editing_message_id == message.id do %>
            <%!-- Edit mode --%>
            <.form for={@edit_form} id="edit-form-#{message.id}" phx-submit="save_edit">
              ...
            </.form>
          <% end %>
        </div>
      </div>

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections

### LiveView JavaScript interop

- Remember anytime you use `phx-hook="MyHook"` and that JS hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Always** provide an unique DOM id alongside `phx-hook` otherwise a compiler error will be raised

LiveView hooks come in two flavors, 1) colocated js hooks for "inline" scripts defined inside HEEx,
and 2) external `phx-hook` annotations where JavaScript object literals are defined and passed to the `LiveSocket` constructor.

#### Inline colocated js hooks

**Never** write raw embedded `<script>` tags in heex as they are incompatible with LiveView.
Instead, **always use a colocated js hook script tag (`:type={Phoenix.LiveView.ColocatedHook}`)
when writing scripts inside the template**:

    <input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
      export default {
        mounted() {
          this.el.addEventListener("input", e => {
            let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
            if(match) {
              this.el.value = `${match[1]}-${match[2]}-${match[3]}`
            }
          })
        }
      }
    </script>

- colocated hooks are automatically integrated into the app.js bundle
- colocated hooks names **MUST ALWAYS** start with a `.` prefix, i.e. `.PhoneNumber`

#### External phx-hook

External JS hooks (`<div id="myhook" phx-hook="MyHook">`) must be placed in `assets/js/` and passed to the
LiveSocket constructor:

    const MyHook = {
      mounted() { ... }
    }
    let liveSocket = new LiveSocket("/live", Socket, {
      hooks: { MyHook }
    });

#### Pushing events between client and server

Use LiveView's `push_event/3` when you need to push events/data to the client for a phx-hook to handle.
**Always** return or rebind the socket on `push_event/3` when pushing events:

    # re-bind socket so we maintain event state to be pushed
    socket = push_event(socket, "my_event", %{...})

    # or return the modified socket directly:
    def handle_event("some_event", _, socket) do
      {:noreply, push_event(socket, "my_event", %{...})}
    end

Pushed events can then be picked up in a JS hook with `this.handleEvent`:

    mounted() {
      this.handleEvent("my_event", data => console.log("from server:", data));
    }

Clients can also push an event to the server and receive a reply with `this.pushEvent`:

    mounted() {
      this.el.addEventListener("click", e => {
        this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply from server:", reply));
      })
    }

Where the server handled it via:

    def handle_event("my_event", %{"one" => 1}, socket) do
      {:reply, %{two: 2}, socket}
    end

### LiveView tests

- `Phoenix.LiveViewTest` module and `LazyHTML` (included) for making your assertions
- Form tests are driven by `Phoenix.LiveViewTest`'s `render_submit/2` and `render_change/2` functions
- Come up with a step-by-step test plan that splits major test cases into small, isolated files. You may start with simpler tests that verify content exists, gradually add interaction tests
- **Always reference the key element IDs you added in the LiveView templates in your tests** for `Phoenix.LiveViewTest` functions like `element/2`, `has_element/2`, selectors, etc
- **Never** tests again raw HTML, **always** use `element/2`, `has_element/2`, and similar: `assert has_element?(view, "#my-form")`
- Instead of relying on testing text content, which can change, favor testing for the presence of key elements
- Focus on testing outcomes rather than implementation details
- Be aware that `Phoenix.Component` functions like `<.form>` might produce different HTML than expected. Test against the output HTML structure, not your mental model of what you expect it to be
- When facing test failures with element selectors, add debug statements to print the actual HTML, but use `LazyHTML` selectors to limit the output, ie:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Form handling

#### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected to have string keys.

You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`.

In the template, the form form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

#### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always access forms this**:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

And **never** do this:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template as it will cause errors
- **Never** use `<.form let={f} ...>` in the template, instead **always use `<.form for={@form} ...>`**, then drive all form references from the form assign as in `@form[:field]`. The UI should **always** be driven by a `to_form/2` assigned in the LiveView module that is derived from a changeset
<!-- phoenix:liveview-end -->

<!-- phoenix:liveview-advanced-start -->
## LiveView — Advanced UX patterns

- Use `temporary_assigns` to reduce memory when rendering large or frequently appended lists.
- Prefer `handle_params/3` for URL‑driven state and back/forward navigation; use `push_patch`/`push_navigate` for transitions.
- For real‑time updates, broadcast minimal events from contexts and handle them with `handle_info/2` in views; refetch affected records instead of sending full payloads.
- Use `Phoenix.LiveView.JS` for small UI interactions (confirmations, toggles) instead of custom inline JS.
- Add explicit loading/disabled states to buttons and forms; use `phx-disable-with` and Tailwind opacity/cursor utilities for polish.
- For large forms, split into logical sections; validate on change and save on submit; never perform long‑running work in `handle_event/3`—offload to Oban and surface progress via PubSub/streams.
### Presence & Streams

- Presence wrapper: provide a `Presence` module via `use Phoenix.Presence` with a custom `fetch/2` that enriches metas (e.g., preload users), and a `subscribe/1` that encapsulates topic naming.
- Local broadcasts: for presence diffs, prefer `Phoenix.PubSub.local_broadcast/3` via proxy topics when updates are only needed on the local node.
- Streams + temporary assigns: render collections with `phx-update="stream"` and reduce memory by setting `temporary_assigns` for presence maps and large lists.
- Assign defaults with `assign_new/3` to avoid recomputation across updates.

### Uploads

- Use `allow_upload/3` with `progress` callbacks and `consume_uploaded_entry/3` to persist files; offload file introspection (e.g., metadata parsing) to a `Task.Supervisor` and send component updates via `send_update/2`.
- Keep upload changesets per entry ref; validate and drop invalid uploads early; cap max entries and size.
### Domain events

- Provide a small `Events` module that wraps `Phoenix.PubSub` with topic helpers and a `use` macro for contexts to `subscribe/1` and `broadcast!/2`.
- Prefer broadcasting minimal payloads (ids) and refetching in subscribers.
- Keep an optional event registry only if exposing events to external consumers; otherwise keep events internal and typed via structs.
<!-- phoenix:liveview-advanced-end -->

<!-- phoenix:testing-start -->
## Testing strategy

- Unit: pure functions under contexts; no DB.
- Integration: `DataCase` for DB interactions; favor `Ecto.Multi` happy/edge paths. Use factories/fixtures that build minimal valid structs.
- Web: `ConnCase` for controllers/API; `LiveViewTest` with `element/2`, `render_click/1`, `render_submit/2`, and IDs from templates.
- Processes: supervise with `start_supervised!/1`. Use `Process.monitor/1` + `assert_receive` for lifecycle, never `Process.sleep/1`.
- External integrations: define behaviours and use `Mimic` to stub or assert interactions in tests. Avoid hitting the network in tests.
- Background jobs: use `Oban.Testing` to assert enqueued and perform jobs synchronously where appropriate.
- Property tests: sparingly, for parsers/encoders and invariants.
- E2E: use `Wallaby` with Chrome for critical happy-path flows. Target elements via stable IDs you add in templates.
- Presence testing: provide a small presence client mock or helpers to simulate joins/leaves and assert UI updates without real clusters.
<!-- phoenix:testing-end -->

<!-- phoenix:observability-start -->
## Observability & Operations

- Telemetry: instrument key boundaries (DB, HTTP, jobs). Prefer structured events with small maps; include ids, not full structs.
- Tracing: if enabled, use `opentelemetry_phoenix`, `opentelemetry_ecto`, `opentelemetry_oban`.
- Logging: structured logs with consistent metadata (request_id, user_id). Log at info for workflows, debug for development noise, warn/error only for actionable issues. Avoid logging secrets.
- Health: add lightweight readiness/liveness routes; avoid expensive checks.
- Metrics: export latency histograms, error rates, queue sizes. Alert on SLO breaches, not raw errors.
 - Sampler: configure OpenTelemetry sampling ratio via env; export to Honeycomb/OTLP when keys present, otherwise disable in dev/test. Start metrics collection with PromEx only if enabled.
<!-- phoenix:observability-end -->

<!-- phoenix:config-start -->
## Configuration & Releases

- Prefer runtime configuration (`config/runtime.exs`) and environment variables; minimize compile‑time deps.
- Keep secrets out of repo; use env vars or a secrets manager.
- Provide sane defaults for development; fail fast in production when required env is missing (validated via `NimbleOptions` at boot when applicable).
- Use `mix release`; keep migration task (`eval Elixir.Events.Release.migrate`) and a rollback plan.
<!-- No feature flags initially; add only when needed. -->
### Supabase + Fly.io

- Database: use `DATABASE_URL` from Supabase and enable SSL verification. Provide a CA cert via `DB_SSL_CACERT_BASE64` secret, write to a file with `0400` permissions, and set Repo `ssl: [cacertfile: ..., verify: :verify_peer]`.
- Fly: set `PHX_SERVER=true`, `PHX_HOST`, `PORT`, and define `release_command` to run migrations. Bind IPv6 `ip: {0,0,0,0,0,0,0,0}` and set `internal_port` 8080.
- Secrets: centralize env parsing with a `ConfigHelpers.get_env/3` that casts to types and fails fast for required values.
<!-- phoenix:config-end -->

<!-- phoenix:security-start -->
## Security

- Use verified routes, CSRF protection, and content security headers. Never inline scripts/styles in templates.
- Validate and constrain inputs with changesets and database constraints. Avoid mass‑assigning sensitive fields.
- Authenticate with `phx.gen.auth` patterns; keep current user in socket assigns via `on_mount` hooks.
- Authorize at the context boundary with simple policy modules; return `{:error, :unauthorized}` and handle at the caller.
- Rate limit sensitive endpoints using a simple ETS counter or a plug; prefer per‑IP + per‑account limits.
- Sanitize user‑provided HTML with `Phoenix.HTML` safe content or explicit sanitizers; default to plain text.
<!-- phoenix:security-end -->

<!-- phoenix:performance-start -->
## Performance

- Prefer queries with proper indexes over caching. When caching is justified, use bounded ETS tables supervised with clear invalidation, or use HTTP cache headers for API responses.
- Stream large lists to the client with LiveView streams and pagination; avoid rendering unbounded collections.
- Concurrency: use `Task.async_stream/3` with `timeout: :infinity` and limited `max_concurrency` for IO‑bound fan‑out.
- Avoid N+1 with explicit preloads tuned to template needs; never preload entire associations without filters.
- Use `Repo.checkout/1` for tight loops that issue many queries sequentially.
<!-- phoenix:performance-end -->

<!-- phoenix:api-start -->
## APIs & Integrations

- Outbound HTTP: centralize `Req` clients per service with default middlewares (auth, base URL, JSON). Use request ids and timeouts; parse responses strictly and map to domain structs.
- No public API initially. When introducing one later: version under `/api`, validate requests, use consistent error envelopes, and generate an OpenAPI spec for consumers.
- Webhooks (later): verify signatures at the plug, enqueue processing to Oban, and respond 2xx quickly.
<!-- phoenix:api-end -->

<!-- phoenix:project-notes-start -->
## Project‑specific notes

- This app is LiveView‑first. Do not introduce React or SPA frameworks. For small client behaviors, prefer `Phoenix.LiveView.JS` or colocated hooks.
- Draw from established open-source Phoenix patterns (presence wrappers, PubSub broadcasting with typed events, disciplined DB indexing, background jobs, adapter-driven integrations), but keep the guidance generic and tailored to this codebase.
- For Accomplish, only reuse backend patterns (contexts, jobs, adapters); ignore React/frontend patterns.
<!-- phoenix:project-notes-end -->

<!-- usage-rules-end -->
