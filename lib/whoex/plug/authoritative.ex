defmodule Whoex.Plug.Authoritative do
  @moduledoc """
  Set authoritative records if any
  """
  use Whoex.Plug

  alias Whoex.App
  alias Whoex.Zones

  @doc false
  def init(opts) do
    App.add_child({Whoex.Storage, :zones})
    App.add_child({Whoex.Loader, [:zones, opts]})
    :ok
  end

  @doc false
  def call(conn, _) do
    conn
    |> query()
    |> Zones.get_authority()
    |> case do
      nil ->
        conn

      authority ->
        conn
        |> authority(authority)
    end
  end
end
