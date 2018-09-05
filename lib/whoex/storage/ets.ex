defmodule Whoex.Storage.Ets do
  @moduledoc """
  Ets storage backend for Whoex
  """
  require Logger

  @behaviour Whoex.Storage

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  @doc """
  Start Ets tables
  """
  def start_link(_opts) do
    Logger.info("Starting DNS ETS storage")
    [
      {:zones, :set},
      {:authorities, :set},
      {:packet_cache, :set},
      {:host_throttle, :set},
      {:lookup_table, :set}
    ]
    |> Enum.map(&table_spec/1)
    |> Supervisor.start_link(strategy: :one_for_one)
  end

  @doc false
  def select(table, key) do
    :ets.lookup(table, key)
  end

  ###
  ### Priv
  ###
  defp table_spec({name, type}) do
    %{
      id: :"#{__MODULE__}_#{name}",
      start: {Agent, :start_link, [fn -> create_ets_table(name, type) end]}
    }
  end

  defp create_ets_table(name, type) do
    case :ets.info(name) do
      :undefined ->
        case :ets.new(name, [type, :public, :named_table]) do
          ^name ->
            :ok

          err ->
            {:error, err}
        end

      _ ->
        :ok
    end
  end
end
