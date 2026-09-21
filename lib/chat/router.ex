defmodule Chat.Router do
  use Plug.Router

  # Root project dir — naik 2 level dari lib/chat/ ke proyek root
  @project_root Path.expand("../..", __DIR__)
  @static_css  Path.join(@project_root, "priv/static/css")
  @static_js   Path.join(@project_root, "priv/static/js")
  @template    Path.join(@project_root, "lib/chat/templates/index.html")

  plug Plug.Static, at: "/css", from: @static_css, only: ~w(chat.css)
  plug Plug.Static, at: "/js", from: @static_js, only: ~w(chat.js)

  plug(:match)
  plug(:dispatch)

  get "/" do
    template =
      @template
      |> File.read!()
      |> String.replace("@TITLE@", "Craft Chat")

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, template)
  end

  get "/events" do
    {:ok, _} = Registry.register(Chat.Registry, :sse, [])

    conn
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> loop_sse()
  end

  post "/message" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    msg = body |> URI.decode_query() |> Map.get("msg", "")

    cfg = Application.fetch_env!(:craft_chat, :openrouter)

    case Req.post("https://openrouter.ai/api/v1/chat/completions",
           json: %{model: cfg[:model], messages: [%{role: "user", content: msg}]},
           headers: %{"authorization" => "Bearer #{cfg[:api_key]}"},
           retry: false) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        reply = body["choices"] |> hd() |> get_in(["message", "content"])

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, "<p>#{Plug.HTML.html_escape(reply)}</p>")

      {:ok, %Req.Response{status: status, body: err}} ->
        send_resp(conn, status, "OpenRouter error: #{inspect(err["error"] || err)}")

      {:error, reason} ->
        send_resp(conn, 502, "request gagal: #{inspect(reason)}")
    end
  end

  match _ do
    send_resp(conn, 404, "404")
  end

  defp loop_sse(conn) do
    receive do
      {:chat_msg, msg} ->
        case Plug.Conn.chunk(conn, "data: #{msg}\n\n") do
          {:ok, conn} -> loop_sse(conn)
          {:error, _} -> conn
        end
    after
      15_000 ->
        case Plug.Conn.chunk(conn, ": ping\n\n") do
          {:ok, conn} -> loop_sse(conn)
          {:error, _} -> conn
        end
    end
  end
end
