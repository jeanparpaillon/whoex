defmodule Whoex.Server.Udp do
  @moduledoc """
  DNS server UDP acceptor
  """
  require Logger
  use GenServer

  defstruct socket: nil, pool_id: nil, plug: nil, plug_opts: nil

  @doc false
  def child_spec([ip, port, _pool_id, _plug, _pluig_opts] = args) do
    %{
      id: :"#{__MODULE__}_[#{:inet.ntoa(ip)}]:#{port}",
      start: {__MODULE__, :start_link, args},
      type: :worker,
      restart: :permanent
    }
  end

  @doc false
  def start_link(ip, port, pool_id, plug, plug_opts) do
    GenServer.start_link(__MODULE__, [ip, port, pool_id, plug, plug_opts])
  end

  ###
  ### GenServer callbacks
  ###
  def init([ip, port, pool_id, plug, plug_opts]) do
    opts = [:binary, {:active, 100}, {:read_packets, 1000}, family(ip)]

    opts =
      case ip do
        {0, 0, 0, 0} -> opts
        {0, 0, 0, 0, 0, 0, 0, 0} -> opts
        _ -> [{:ip, ip} | opts]
      end

    state = %__MODULE__{
      pool_id: pool_id,
      plug: plug,
      plug_opts: plug_opts
    }

    Logger.info("<DNS> listen on udp://#{:inet.ntoa(ip)}:#{port}")

    case :gen_udp.open(port, opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}}

      {:error, _} = err ->
        err
    end
  end

  def handle_info({:udp, socket, host, port, bin}, state) do
    msg = {:query, socket, host, port, bin, state.plug, state.plug_opts}
    :poolboy.transaction(state.pool_id, &GenServer.cast(&1, msg))
    {:noreply, state}
  end

  def handle_info(
        {:udp_socket, socket},
        state
      ) do
    :inet.setopts(socket, active: 100)
    {:noreply, state}
  end

  def terminate(_reason, state) do
    :ok = :gen_udp.close(state.socket)
    :ok
  end

  ###
  ### Priv
  ###
  defp family({_, _, _, _}), do: :inet

  defp family({_, _, _, _, _, _, _, _}), do: :inet6
end
