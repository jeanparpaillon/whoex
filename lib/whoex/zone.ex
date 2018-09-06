defmodule Whoex.Zone do
  @moduledoc """
  Structure for DNS zone
  """
  use Whoex.Records
  use Whoex.Constants

  alias Whoex.Helpers
  alias Whoex.Keyset

  defstruct name: nil,
            version: nil,
            authorities: [],
            record_count: 0,
            records: [],
            records_by_name: %{},
            keysets: []

  @type t :: %__MODULE__{
          name: Whoex.dname(),
          version: String.t(),
          authorities: [dns_rr],
          record_count: non_neg_integer,
          records: [dns_rr],
          records_by_name: %{String.t() => [dns_rr]},
          keysets: [Keyset.t()]
        }

  @doc """
  Creates new zone
  """
  @spec new(Whoex.dname(), String.t(), [dns_rr], [Keyset.t()]) :: t
  def new(name, version, records, keys \\ []) do
    records_by_name = build_named_index(records)

    authorities =
      records
      |> Enum.filter(match_type(@_DNS_TYPE_SOA))

    %__MODULE__{
      name: Helpers.normalize_name(name),
      version: version,
      record_count: length(records),
      authorities: authorities,
      records: records,
      records_by_name: records_by_name,
      keysets: keys
    }
  end

  def authorities(%__MODULE__{authorities: authorities}) do
    authorities
  end

  ###
  ### Priv
  ###
  defp build_named_index(records) do
    records
    |> Enum.reduce(%{}, fn record, acc ->
      name =
        record
        |> dns_rr(:name)
        |> Helpers.normalize_name()

      Map.update(acc, name, [record], fn cur -> [record | cur] end)
    end)
    |> Enum.map(fn {key, value} ->
      {key, Enum.reverse(value)}
    end)
  end
end
