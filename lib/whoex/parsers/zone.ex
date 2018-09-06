defmodule Whoex.Parsers.Zone do
  @moduledoc """
  Parse zone from JSON
  """
  use Whoex.Constants
  use Whoex.Records
  require Logger

  alias Whoex.Helpers  
  alias Whoex.Zone

  @type priv_path :: {:priv, atom, Path.t()}

  @doc """
  Parse given file
  """
  @spec parse_file!(Path.t() | priv_path) :: [Zone.t()]
  def parse_file!({:priv, app, path}) do
    app
    |> :code.priv_dir()
    |> Path.join(path)
    |> parse_file!()
  end

  def parse_file!(filename) do
    filename
    |> File.read!()
    |> Jason.decode!()
    |> parse!()
  end

  @doc """
  Parse a JSON list
  """
  @spec parse!([map]) :: [Zone.t()]
  def parse!(zones) do
    zones
    |> Enum.map(&parse_zone/1)
  end

  @doc """
  Parse a single zone from JSON map
  """
  @spec parse_zone(map) :: Zone.t()
  def parse_zone(zone) do
    name = Map.fetch!(zone, "name")
    sha = Map.get(zone, "sha", "")

    records =
      zone
      |> Map.get("records", [])
      |> Enum.map(&parse_record/1)
      |> Enum.filter(& &1)

    keys =
      zone
      |> Map.get("keys", [])
      |> Enum.map(&parse_key/1)
      |> Enum.filter(& &1)

    Zone.new(name, sha, records, keys)
  end

  defp parse_record(record) do
    parse_record(
      Map.get(record, "name", nil),
      Map.get(record, "type", nil),
      Map.get(record, "ttl", nil),
      Map.get(record, "data", nil)
    )
  end

  defp parse_record(name, type, _, nil) do
    Logger.error("Missing data in record #{name} (#{type})")
    nil
  end

  defp parse_record(name, "SOA", ttl, data) do
    dns_rr(
      name: Helpers.normalize_name(name),
      type: @_DNS_TYPE_SOA,
      data: dns_rrdata_soa(
        mname: Map.get(data, "mname"),
        rname: Map.get(data, "rname"),
        serial: Map.get(data, "serial"),
        refresh: Map.get(data, "refresh"),
        retry: Map.get(data, "retry"),
        expire: Map.get(data, "expire"),
        minimum: Map.get(data, "minimum")
      ),
      ttl: ttl
    )
  end

  defp parse_record(name, type, _, _) do
    Logger.warn("Ignore record #{name} (#{type})")
    nil
  end

  defp parse_key(_key) do
    Logger.warn("Ignore key parsing (TODO)")
    nil
  end
end
