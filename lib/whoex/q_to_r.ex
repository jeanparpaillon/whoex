defmodule Whoex.QtoR do
  @moduledoc """
  Simple plug turning query into answer
  """
  use Whoex.Plug
  
  def init(_opts), do: :ok

  def call(conn, _) do
    query = query(conn)
    reply = dns_message(query, qr: 1)

    conn |> resp(reply)
  end
end
