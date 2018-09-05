defmodule Whoex.Plug.QtoR do
  @moduledoc """
  Simple plug turning query into answer if no reply
  """
  use Whoex.Plug

  def init(_opts), do: :ok

  def call(%{state: :set} = conn, _), do: conn

  def call(conn, _) do
    query = query(conn)
    reply = dns_message(query, qr: 1)

    conn |> resp(reply)
  end
end
