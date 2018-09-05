defmodule Whoex.Storage.Zone do
  @moduledoc """
  Defines zone record (used for storage)
  """
  import Record

  defrecord :zone,
    name: nil,
    version: nil,
    authority: [],
    record_count: 0,
    records: [],
    records_by_name: %{}

  def fields,
    do: [
      :name,
      :version,
      :authority,
      :record_count,
      :records,
      :records_by_name,
      :records_by_type,
      :keysets
    ]
end
