defmodule Whoex.Server.Handler do
  @moduledoc """
  Handle a DNS connection and connect it with plug
  """
  @already_sent {:whoex_conn, :sent}

  @doc false
  def call(conn, plug, opts) do
    try do
      conn
      |> plug.call(opts)
      |> maybe_send(plug)
    catch
      :error, value ->
        stack = System.stacktrace()
        exception = Exception.normalize(:error, value, stack)
        reason = {{exception, stack}, {plug, :call, [conn, opts]}}
        terminate(reason, conn, stack)

      :throw, value ->
        stack = System.stacktrace()
        reason = {{{:nocatch, value}, stack}, {plug, :call, [conn, opts]}}
        terminate(reason, conn, stack)

      :exit, value ->
        stack = System.stacktrace()
        reason = {value, {plug, :call, [conn, opts]}}
        terminate(reason, conn, stack)
    after
      receive do
        @already_sent -> :ok
      after
        0 -> :ok
      end
    end
  end

  defp maybe_send(%Whoex.Conn{state: :unset}, _plug), do: raise(Whoex.Conn.NotSentError)
  defp maybe_send(%Whoex.Conn{state: :set} = conn, _plug), do: Whoex.Conn.send_resp(conn)
  defp maybe_send(%Whoex.Conn{} = conn, _plug), do: conn

  defp terminate(reason, _req, _stack) do
    exit(reason)
  end
end
