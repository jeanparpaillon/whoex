defmodule Whoex.Zones do
  @moduledoc """
  Store and retrieve authoritative zones
  """
  use Whoex.Records

  alias Whoex.Conn
  alias Whoex.Helpers
  alias Whoex.Zone
  alias Whoex.Storage

  @doc """
  Retrieve authority records for given query message
  (last question only)
  """
  @spec get_authority(dns_query | Conn.dname) :: nil | [dns_rr]
  def get_authority(dns_query(name: name)) do
    get_authority(name)
  end

  def get_authority(name) do
    name
    |> find_zone_in_cache()
    |> case do
         nil -> nil
         zone -> Zone.authorities(zone)
       end
  end

  @doc """
  Store zone
  """
  def put(%Zone{name: name} = zone) do
    Storage.insert(:zones, {Helpers.normalize_name(name), zone})
  end

  ###
  ### Priv
  ###
  def find_zone_in_cache(name) do
    name = Helpers.normalize_name(name)
    find_zone_in_cache(name, :dns.dname_to_labels(name))
  end

  defp find_zone_in_cache(_name, []), do: nil

  defp find_zone_in_cache(name, [_ | labels]) do
    case Storage.select(:zones, name) do
      [{^name, zone}] ->
        zone

      _ ->
        case labels do
          [] ->
            nil

          _ ->
            find_zone_in_cache(:dns.labels_to_dname(labels))
        end
    end
  end
end
