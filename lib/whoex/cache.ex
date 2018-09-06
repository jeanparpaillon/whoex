defmodule Whoex.Cache do
  @moduledoc """
  Manages cache
  """
  require Logger
  use GenServer

  alias Whoex.Storage

  @default_ttl 20
  @default_sweep_interval 1000 * 60 * 3

  defstruct ttl: @default_ttl, tref: nil

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc false
  def start_link(opts) do
    Logger.info("Starting DNS cache (#{inspect(opts)})")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Fetch packet from cache
  """
  def get(key) do
    case Storage.select(:packet_cache, key) do
      [{_key, {response, expires_at}}] ->
        if timestamp() > expires_at do
          {:error, :cache_expired}
        else
          {:ok, response}
        end

      _ ->
        {:error, :cache_miss}
    end
  end

  @doc """
  Store response in cache
  """
  def put(key, response) do
    GenServer.call(__MODULE__, {:set_packet, [key, response]})
  end

  @doc """
  Cleanup old responses
  """
  def sweep, do: GenServer.cast(__MODULE__, :sweep)

  ###
  ### GenServer callbacks
  ###
  def init(opts) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    sweep_interval = Keyword.get(opts, :sweep_interval, @default_sweep_interval)

    {:ok, tref} = :timer.apply_interval(sweep_interval, __MODULE__, :sweep, [])

    {:ok, %__MODULE__{ttl: ttl, tref: tref}}
  end

  def handle_call({:set_packet, [key, response]}, _from, s) do
    Storage.insert(:packet_cache, {key, {response, timestamp() + s.ttl}})
    {:reply, :ok, s}
  end

  def handle_cast(:sweep, s) do
    :packet_cache
    |> Storage.select(
      [{{:"$1", {:_, :"$2"}}, [{:<, :"$2", timestamp() - 10}], [:"$1"]}],
      :infinite
    )
    |> Enum.each(fn key -> Storage.delete(:packet_cache, key) end)

    {:noreply, s}
  end

  def handle_cast(:clear, s) do
    Storage.empty_table(:packet_cache)
    {:noreply, s}
  end

  ###
  ### Priv
  ###
  defp timestamp do
    {tm, ts, _} = :os.timestamp()
    tm * 1_000_000 + ts
  end
end
