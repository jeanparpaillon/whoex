defmodule Whoex.Cache do
  @moduledoc """
  A basic packet cache

  Adapter may require to be started before using this plug
  """
  require Logger

  use Whoex.Plug

  alias Whoex.Helpers

  def init(opts) do
    adapter = Keyword.get(opts, :adapter, Whoex.Storage.Ets)

    %{adapter: adapter}
  end

  def call(conn, %{adapter: adapter}) do
    key = {questions(conn), additional(conn)}

    conn =
      case adapter.select(:packet_cache, key) do
        [{_key, {response, expires_at}}] ->
          case timestamp() > expires_at do
            true ->
              Logger.debug(fn -> "Cache expires on #{Helpers.fmt_questions(response)}" end)
              conn

            false ->
              Logger.debug(fn -> "Cache hit on #{Helpers.fmt_questions(response)}" end)

              conn
              |> resp(dns_message(response, id: query_id(conn)))
          end

        _ ->
          Logger.debug(fn -> "Cache miss on #{Helpers.fmt_questions(query(conn))}" end)
          conn
      end

    register_before_send(conn, fn conn ->
      # Cache write can be asynchronous
      _ = spawn(fn -> maybe_cache_packet(conn, adapter) end)
      conn
    end)
  end

  ###
  ### Priv
  ###
  defp timestamp do
    {tm, ts, _} = :os.timestamp()
    tm * 1_000_000 + ts
  end

  defp maybe_cache_packet(conn, adapter) do
    try do
      if aa?(conn) do
        resp = response(conn)
        Logger.debug(fn -> "Cache response #{Helpers.fmt_answers(resp)}" end)
        adapter.put({dns_message(resp, :questions), dns_message(resp, :additional)}, resp)
      end
    rescue
      _ ->
        :ok
    end
  end
end
