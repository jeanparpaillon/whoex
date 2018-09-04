defmodule Whoex.Decoder do
  @moduledoc """
  Decoder for DNS messages
  """

  @doc """
  Decode DNS message

  Raise exception if error
  """
  def decode!(bin) do
    case :dns.decode_message(bin) do
      {:trailing_garbage, decoded, _} ->
        decoded

      {_, _, _} = err ->
        raise "Error decoding DNS message: #{inspect(err)}"

      decoded ->
        decoded
    end
  end

  @doc """
  Decode DNS message
  """
  def decode(bin) do
    :dns.decode_message(bin)
  end
end
