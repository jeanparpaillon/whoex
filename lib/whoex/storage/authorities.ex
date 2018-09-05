defmodule Whoex.Storage.Authorities do
  @moduledoc """
  Authorities record definitions
  """
  import Record

  defrecord :authorities,
    owner_name: nil,
    ttl: nil,
    class: nil,
    name_server: nil,
    email_addr: nil,
    serial_num: nil,
    refresh: nil,
    retry: nil,
    expiry: nil,
    nxdomain: nil

  def fields,
    do: [
      :owner_name,
      :ttl,
      :class,
      :name_server,
      :email_addr,
      :serial_num,
      :refresh,
      :retry,
      :expiry,
      :nxdomain
    ]
end
