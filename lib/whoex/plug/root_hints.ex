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

    conn
    |> Map.merge(%{
          authority: authority, additional: additional,
          aa: false, rc: @_DNS_RCODE_REFUSED})
    |> send_resp()
  end
  
  def call(conn, _) do
    conn
  end
end
