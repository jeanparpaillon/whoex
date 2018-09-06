defmodule Whoex.Plug.RootHints do
  @moduledoc """
  Respond root hints if not authoritative
  """
  require Logger
  use Whoex.Plug

  alias Whoex.Conn

  @doc false
  def init(_opts) do
    :ok
  end

  @doc false
  def call(%Conn{authority: []} = conn, _) do
    {authority, additional} = root_hints()
    response =
      conn
      |> query()
      |> dns_message(aa: false, rc: @_DNS_RCODE_REFUSED, authority: authority, additional: additional)
    
    resp(conn, response)
  end
  
  def call(conn, _) do
    conn
  end
end
