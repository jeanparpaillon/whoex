defmodule Whoex.Loader do
  @moduledoc """
  Data loader

  Used by `Whoex.Plug.Authoritative` for instance for loading authority records
  """
  require Logger

  alias Whoex.Zones
  alias Whoex.Parsers

  @doc false
  def child_spec([:zones, opts]) do
    fn -> load_zones(opts) end
    |> Task.child_spec()
    |> Map.put(:id, {__MODULE__, :zones, opts})
  end

  @doc """
  Load zones from file
  """
  def load_zones(opts) do
    Logger.info("Loading zones...")
    opts
    |> Keyword.get(:file, "zones.json")
    |> Parsers.Zone.parse_file!()
    |> Enum.each(&Zones.put/1)
  end
end
