defmodule Whoex.Server.UdpWorker do
  @moduledoc """
  DNS server UDP wrapper
  """
  use GenServer

  alias Whoex.Conn.Udp, as: Conn
  alias Whoex.Server.Handler

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def init(_), do: {:ok, :ok}

  def handle_cast({:query, socket, from, port, bin, plug, plug_opts}, :ok) do
    bin
    |> Conn.conn(from, port, socket)
    |> Handler.call(plug, plug_opts)

    {:noreply, :ok}
  end
end
