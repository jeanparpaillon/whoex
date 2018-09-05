defmodule Whoex.Storage do
  @moduledoc """
  Storage behaviour
  """
  @type key :: term
  @type table :: atom
  @type record :: tuple

  @callback select(table, key) :: [record]
end
