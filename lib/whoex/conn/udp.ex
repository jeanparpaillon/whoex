defmodule Whoex.Conn.Udp do
  @behaviour Whoex.Conn.Adapter
  @moduledoc false

  require Record
  require Whoex.Records

  defstruct message: nil, socket: nil, from: nil, port: nil

  alias Whoex.Records
  alias Whoex.Decoder
  alias Whoex.Encoder

  @max_packet_size 512

  def conn(data, from, port, socket) do
    message = Decoder.decode!(data)

    req = %__MODULE__{
      socket: socket,
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
    encoded =
      case Encoder.encode(message, max_size: max_payload_size(message)) do
        {false, encoded} -> encoded
        {true, encoded, _message} -> encoded
        {false, encoded, _tsig_mac} -> encoded
        {true, encoded, _tsig_mac, _message} -> encoded
      end

    :gen_udp.send(req.socket, req.from, req.port, encoded)
    {:ok, req}
  end

  def get_peer_data(req) do
    %{
      address: req.from,
      port: req.port
    }
  end

  ###
  ### Priv
  ###
  defp max_payload_size(message) do
    case Records.dns_message(message, :additional) do
      [opt | _] when Record.is_record(opt, :dns_optrr) ->
        case Records.dns_optrr(opt, :udp_payload_size) do
          [] ->
            @max_packet_size

          size ->
            size
        end

      _ ->
        @max_packet_size
    end
  end
end

defimpl Inspect, for: Whoex.Server.UdpConnection do
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
