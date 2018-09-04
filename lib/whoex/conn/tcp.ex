defmodule Whoex.Conn.Tcp do
  @behaviour Whoex.Conn.Adapter
  @moduledoc false

  defstruct message: nil, socket: nil, transport: nil, from: nil, port: nil

  alias Whoex.Decoder
  alias Whoex.Encoder

  def conn(data, from, port, socket, transport) do
    data
    |> Decoder.decode()
    |> do_conn(from, port, socket, transport)
  end

  defp do_conn({:error, _} = e, _, _, _, _), do: e

  defp do_conn({:truncated, _, bin}, _, _, _, _), do: {:more, bin}

  defp do_conn(message, from, port, socket, transport) do
    req = %__MODULE__{
      socket: socket,
      transport: transport,
      from: from,
      port: port
    }

    %Whoex.Conn{
      adapter: {__MODULE__, req},
      owner: self(),
      query: message
    }
  end

  def send_resp(req, message) do
    encoded = Encoder.encode!(message)
    len = :erlang.byte_size(encoded)
    :ok = req.transport.send(req.socket, <<len::size(16), encoded::binary>>)
    {:ok, req}
  end

  def get_peer_data(req) do
    %{
      address: req.from,
      port: req.port
    }
  end
end

defimpl Inspect, for: Whoex.Server.TcpConnection do
  def inspect(conn, opts) do
    conn =
      if opts.limit == :infinity do
        conn
      else
        update_in(conn.adapter, fn {adapter, _data} -> {adapter, :...} end)
      end

    Inspect.Any.inspect(conn, opts)
  end
end
