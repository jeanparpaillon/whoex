defmodule Whoex.Conn.Adapter do
  @moduledoc """
  Specification of the connection adapter API implemented by DNS server
  """
  @type message :: iodata
  @type payload :: term
  @type peer_data :: %{
          address: :inet.ip_address(),
          port: :inet.port_number()
        }

  @doc """
  Sends the given message back to the client.
  """
  @callback send_resp(payload, message) :: {:ok, payload}

  @doc """
  Returns peer information such as the address, port and ssl cert.
  """
  @callback get_peer_data(payload) :: peer_data()
end
