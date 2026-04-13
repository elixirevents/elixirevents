defmodule ElixirEventsWeb.HealthController do
  use ElixirEventsWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end
end
