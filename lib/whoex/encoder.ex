defmodule Whoex.Encoder do
  @moduledoc """
  DNS message encoder
  """
  alias Whoex.Records

  @type message :: Records.dns_message()
  @type message_id :: 0..65535
  @type message_bin :: binary
  @type dname :: binary
  @type tsig_error :: 0 | 16..18
  @type tsig_mac :: binary
  @type tsig_alg :: binary
  @type unix_time :: 0..4_294_967_295

  @type tsig_opt ::
          {:time, unix_time}
          | {:fudge, non_neg_integer}
          | {:mac, tsig_mac}
          | {:tail, boolean}

  @type encode_message_opt ::
          {:max_size, 512..65535}
          | {:tc_mode, :default | :axfr | :llq_event}
          | {:tsig, [encode_message_tsig_opt]}

  @type encode_message_tsig_opt ::
          {:msgid, message_id}
          | {:alg, tsig_alg}
          | {:name, dname}
          | {:secret, binary}
          | {:errcode, tsig_error}
          | {:other, binary}
          | tsig_opt

  @doc """
  Encode dns_message record
  """
  def encode!(reply) do
    :dns.encode_message(reply)
  end

  @doc """
  Encode dns_message record, with options

  See
  https://github.com/dnsimple/dns_erlang/blob/master/src/dns.erl
  for options
  """
  @spec encode(message, [encode_message_opt]) ::
          {false, message_bin}
          | {true, message_bin, message}
          | {false, message_bin, tsig_mac}
          | {true, message_bin, tsig_mac, message}
  def encode(reply, opts) do
    :dns.encode_message(reply, opts)
  end
end
