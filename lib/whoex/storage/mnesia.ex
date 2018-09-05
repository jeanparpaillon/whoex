defmodule Whoex.Storage.Mnesia do
  @moduledoc """
  Mnesia storage for Whoex

  Copied from :erldns app
  """
  require Logger

  alias Whoex.Storage.Zone
  alias Whoex.Storage.Authorities

  @behaviour Whoex.Storage

  @doc false
  def child_spec(dir) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [dir]}
    }
  end

  @doc """
  Initializes storage
  """
  def start_link(dir) do
    :ok = create(:schema, dir)
    :ok = create(:zones)
    :ok = create(:authorities)
    Agent.start_link(fn -> :ok end)
  end

  @doc """
  callback
  """
  def select(table, key) do
    select = fn ->
      case :mnesia.read({table, key}) do
        [record] -> [{key, record}]
        _ -> []
      end
    end

    :mnesia.activity(:transaction, select)
  end

  ###
  ### Priv
  ###
  defp create(:schema, dir) do
    :ok = ensure_mnesia_started()
    :ok = Application.put_env(:mnesia, :dir, dir, persistent: true)
    :ok = Application.stop(:mnesia)

    case :mnesia.create_schema([node()]) do
      {:error, {_, {:already_exists, _}}} ->
        Logger.warn("The schema already exists (node: #{node()})")
        :ok

      :ok ->
        :ok
    end

    Application.start(:mnesia)
  end

  defp create(:zones) do
    :ok = ensure_mnesia_started()

    case :mnesia.create_table(:zones,
           attributes: Zone.fields(),
           disc_copies: [node()],
           record_name: :zone
         ) do
      {:aborted, {:already_exists, :zones}} ->
        Logger.warn("The zone table already exists (node: #{node()})")
        :ok

      {:atomic, :ok} ->
        :ok

      err ->
        {:error, err}
    end
  end

  defp create(:authorities) do
    :ok = ensure_mnesia_started()

    case :mnesia.create_table(:authorities,
           attributes: Authorities.fields(),
           disc_copies: [node()]
         ) do
      {:aborted, {:already_exists, :zones}} ->
        Logger.warn("The authority table already exists (node: #{node()})")
        :ok

      {:atomic, :ok} ->
        :ok

      err ->
        {:error, err}
    end
  end

  defp ensure_mnesia_started do
    case Application.start(:mnesia) do
      :ok ->
        :ok

      {:error, {:already_started, :mnesia}} ->
        :ok

      {:error, err} ->
        {:error, err}
    end
  end
end
