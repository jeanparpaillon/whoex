defmodule Whoex.Authorities do
  @moduledoc """
  Structure describing zone authority
  """
  defstruct owner_name: nil,
            ttl: nil,
            class: nil,
            name_server: nil,
            email_addr: nil,
            serial_num: nil,
            refresh: nil,
            retry: nil,
            expiry: nil,
            nxdomain: nil

  @type t :: %__MODULE__{}
end
