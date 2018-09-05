defmodule Whoex.Plug.Cache do
  @moduledoc """
  A basic packet cache

  Adapter may require to be started before using this plug
  """
  require Logger
  require Whoex.App

  use Whoex.Plug

  alias Whoex.App
  alias Whoex.Cache
  alias Whoex.Helpers

  def init(opts) do
    App.add_child({Whoex.Storage, :packet_cache})
    App.add_child({Whoex.Cache, opts})
    :ok
  end

  def call(conn, _) do
    key = {questions(conn), additional(conn)}

    conn =
      case Cache.get(key) do
        {:ok, response} ->
          Logger.debug(fn -> "Cache hit on #{Helpers.fmt_questions(response)}" end)

          conn
          |> resp(dns_message(response, id: query_id(conn)))

        {:error, :cache_expired} ->
          Logger.debug(fn -> "Cache expires on #{Helpers.fmt_questions(query(conn))}" end)
          conn

        {:error, :cache_miss} ->
          Logger.debug(fn -> "Cache miss on #{Helpers.fmt_questions(query(conn))}" end)
          conn
      end

    register_before_send(conn, fn conn ->
      # Cache write can be asynchronous
      _ = spawn(fn -> maybe_cache_packet(conn) end)
      conn
    end)
  end

  ###
  ### Priv
  ###
  defp maybe_cache_packet(conn) do
    try do
      if aa?(conn) do
        resp = response(conn)
        Logger.debug(fn -> "Cache response #{Helpers.fmt_answers(resp)}" end)
        Cache.put({dns_message(resp, :questions), dns_message(resp, :additional)}, resp)
      end
    rescue
      _ ->
        :ok
    end
  end
end
