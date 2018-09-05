defmodule Whoex.Storage do
  @moduledoc """
  Manage storage: cache, zones
  """
  require Logger
  
  @doc false
  def child_spec(:packet_cache) do
    table_spec({:packet_cache, :set})
  end
  
  @doc """
  """
  def select(table, key) do
    :ets.lookup(table, key)
  end

  @doc """
  """
  def select(table, match_spec, :infinite) do
    :ets.select(table, match_spec)
  end

  def select(table, match_spec, limit) do
    :ets.select(table, match_spec, limit)
  end

  @doc """
  """
  def insert(table, value) do
    true = :ets.insert(table, value)
    :ok
  end

  @doc """
  """
  def delete(table, key) do
    :ets.delete(table, key)
    :ok
  end

  @doc """
  """
  def empty_table(table) do
    :ets.delete_all_objects(table)
    :ok
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
