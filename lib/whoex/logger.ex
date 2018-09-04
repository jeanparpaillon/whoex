defmodule Whoex.Logger do
  @moduledoc """
  A plug for logging basic request information in the format:

      TBD

  To use it, just plug it into the desired module.

      plug Whoex.Logger, log: :debug

  ## Options

    * `:log` - The log level at which this plug should log its request info.
      Default is `:info`.
  """
  require Whoex.Records
  require Logger

  use Whoex.Constants

  alias Whoex.Records
  alias Whoex.Conn

  @behaviour Whoex.Plug

  def init(opts) do
    Keyword.get(opts, :log, :info)
  end

  def call(conn, level) do
    query = Conn.query(conn)

    Logger.log(level, fn ->
      [fmt_qr(query), ?\s, fmt_questions(query)]
    end)

    start = System.monotonic_time()

    Conn.register_before_send(conn, fn conn ->
      Logger.log(level, fn ->
        stop = System.monotonic_time()
        diff = System.convert_time_unit(stop - start, :native, :microsecond)

        [fmt_qr(not Records.dns_message(query, :qr)), " in ", formatted_diff(diff)]
      end)

      conn
    end)
  end

  ###
  ### Priv
  ###
  defp fmt_qr(Records.dns_message(qr: qr)), do: fmt_qr(qr)
  defp fmt_qr(false), do: "QUERY"
  defp fmt_qr(true), do: "ANSWER"

  defp fmt_questions(Records.dns_message(questions: questions)) do
    questions
    |> Enum.map(&fmt_query/1)
    |> Enum.join(" ")
  end

  defp fmt_query(Records.dns_query(name: name, class: class, type: type)) do
    ["[", name, ?\s, :dns.class_name(class), ?\s, :dns.type_name(type), "]"]
  end

  defp formatted_diff(diff) when diff > 1000, do: [diff |> div(1000) |> Integer.to_string(), "ms"]
  defp formatted_diff(diff), do: [Integer.to_string(diff), "µs"]
end
