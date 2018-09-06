defmodule Whoex.Plug.Cache do
  @moduledoc """
  A basic packet cache

  Adapter may require to be started before using this plug
  """
  require Logger
  require Whoex.App

  use Whoex.Plug

  alias Whoex.Conn
  alias Whoex.App
  alias Whoex.Cache
  alias Whoex.Helpers

  def init(opts) do
    App.add_child({Whoex.Storage, :packet_cache})
    App.add_child({Whoex.Cache, opts})
    :ok
  end

  def call(%Conn{questions: questions, additional: additional} = conn, _) do
    key = {questions, additional}

    conn =
      case Cache.get(key) do
        {:ok, response} ->
          Logger.debug(fn -> "Cache hit on #{Helpers.fmt_questions(questions)}" end)
          resp(conn, response)

        {:error, :cache_expired} ->
          Logger.debug(fn -> "Cache expires on #{Helpers.fmt_questions(questions)}" end)
          conn

        {:error, :cache_miss} ->
          Logger.debug(fn -> "Cache miss on #{Helpers.fmt_questions(questions)}" end)
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
  defp maybe_cache_packet(%Conn{aa: false}), do: :ok
  
  defp maybe_cache_packet(conn) do
    try do
      resp = response(conn)
      Logger.debug(fn -> "Cache response #{Helpers.fmt_answers(resp)}" end)
      Cache.put({conn.questions, conn.additional}, response(conn))
    rescue
      _ ->
        :ok
    end
  end
end
