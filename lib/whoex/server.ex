defmodule Whoex.Server do
  @moduledoc """
  Reference DNS server for whoex

  Use ranch for TCP acceptors pool
  Use poolboy for UDP acceptors pool
  """
  alias Whoex.Server.UdpWorker
  alias Whoex.Server.Udp
  alias Whoex.Server.TcpWorker

  @doc """
  Function for starting server under Elixir v1.5 supervisors.

  It expects two arguments:

    * `plug` - MyPlug or {MyPlug, plug_opts}
    * `options` - See below

  ## Options

    * `:ip` - the ip to bind the server to

    * `:port` - the port to run the server (default: 53)

    * `:acceptors` - the number of acceptors for the listener.
      Defaults to 100.

    * `:max_connections` - max number of connections supported.
      Defaults to `16_384`.
  """
  def child_spec([plug, opts]) do
    ip = Keyword.get_lazy(opts, :ip, fn -> raise "[DNS] Missing opt: :ip" end)
    port = Keyword.get(opts, :port, 53)
    id = :"#{__MODULE__}_[#{:inet.ntoa(ip)}]:#{port}"

    %{
      id: id,
      start: {__MODULE__, :start_link, [plug, opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: :infinity
    }
  end

  @doc """
  Start DNS server
  """
  @spec start_link(plug :: module | {module, term}, opts :: [term()]) :: Supervisor.on_start()
  def start_link(plug, opts) do
    ip = Keyword.get_lazy(opts, :ip, fn -> raise "[DNS] Missing opt: :ip" end)
    port = Keyword.get(opts, :port, 53)
    acceptors = Keyword.get(opts, :acceptors, 100)

    {plug, plug_opts} =
      case plug do
        {_, _} = tuple -> tuple
        plug -> {plug, []}
      end

    pool_id = :"#{__MODULE__}_pool_[#{:inet.ntoa(ip)}]:#{port}"

    pool_opts = [
      name: {:local, pool_id},
      worker_module: UdpWorker,
      size: acceptors,
      max_overflow: acceptors * 2
    ]

    ranch_id = :"#{__MODULE__}_tcp_[#{:inet.ntoa(ip)}]:#{port}"
    ranch_module = :ranch_tcp

    ranch_opts = [
      {:ip, ip},
      {:port, port},
      family(ip)
    ]

    children = [
      :poolboy.child_spec(pool_id, pool_opts, []),
      {Udp, [ip, port, pool_id, plug, plug_opts]},
      :ranch.child_spec(
        ranch_id,
        acceptors,
        ranch_module,
        ranch_opts,
        TcpWorker,
        {plug, plug_opts}
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  ###
  ### Priv
  ###
  defp family({_, _, _, _}), do: :inet

  defp family({_, _, _, _, _, _, _, _}), do: :inet6
end
