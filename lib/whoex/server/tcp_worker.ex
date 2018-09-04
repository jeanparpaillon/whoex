defmodule Whoex.Server.TcpWorker do
  @moduledoc """
  DNS TCP worker
  """
  require Logger

  alias Whoex.Conn.Tcp, as: Conn
  alias Whoex.Server.Handler

  defstruct ref: nil, socket: nil, transport: nil, plug: nil, plug_opts: nil

  @doc false
  def start_link(ref, _socket, transport, {plug, plug_opts}) do
    s = %__MODULE__{
      ref: ref,
      transport: transport,
      plug: plug,
      plug_opts: plug_opts
    }

    pid = spawn_link(__MODULE__, :init, [s])
    {:ok, pid}
  end

  @doc false
  def init(s) do
    {:ok, socket} = :ranch.handshake(s.ref)
    :ok = s.transport.setopts(socket, active: :once)
    loop("", %{s | socket: socket})
  end

  ###
  ### Priv
  ###
  defp loop(acc, %__MODULE__{socket: socket} = s) do
    receive do
      {:tcp, ^socket, bin} ->
        s.transport.setopts(s.socket, active: :once)
        do_process(acc <> bin, s)

      {:tcp_close, ^socket} ->
        terminate(:normal, s)

      {:tcp_error, ^socket, reason} ->
        terminate(reason, s)
    end
  end

  defp do_process(data, s) do
    case :inet.peername(s.socket) do
      {:ok, {from, port}} ->
        do_query(data, from, port, s)

      {:error, err} ->
        Logger.debug(fn -> "<dns> tcp error: #{inspect(err)}" end)
        :ok
    end
  end

  defp do_query(<<_len::size(16), data::binary>>, from, port, s) do
    conn =
      data
      |> Conn.conn(from, port, s.socket, s.transport)
      |> case do
        {:error, err} ->
          terminate(err, s)

        {:more, _} ->
          Logger.info("Received truncated request (address: #{inspect(from)})")
          # loop(data, s)
          terminate(:truncated, s)

        conn ->
          conn
      end

    try do
      Handler.call(conn, s.plug, s.plug_opts)
    after
      terminate(:normal, s)
    end
  end

  defp terminate(_reason, s) do
    :ok = s.transport.close(s.socket)
  end
end
