defmodule Whoex.Plug.ZonesCache do
  @moduledoc """
  Retrieve records from zone cache
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
    |> Map.get(:questions)
    |> Enum.reduce(conn, &resolve/2)
  end

  defp resolve(dns_query(name: name, type: type), conn) do
    resolve(name, type, Zones.get_authority(name), conn)
  end

  defp resolve(_, _, nil, conn) do
    conn
  end
  
  defp resolve(_, @_DNS_TYPE_RRSIG, _, conn) do
    %{conn | rc: @_DNS_RCODE_REFUSED}
  end
  
  defp resolve(_qname, _type, _authority, conn) do
    conn
  end
end
