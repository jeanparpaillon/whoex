defmodule Whoex.Plug.Logger do
  @moduledoc """
  A plug for logging basic request information in the format:

      TBD

  To use it, just plug it into the desired module.

      plug Whoex.Logger, log: :debug

  ## Options

    * `:log` - The log level at which this plug should log its request info.
      Default is `:info`.
  """
  require Logger

  alias Whoex.Helpers

  use Whoex.Plug

  def init(opts) do
    Keyword.get(opts, :log, :info)
  end

  def call(conn, level) do
    query = query(conn)

    Logger.log(level, fn ->
      [fmt_qr(query), ?\s, Helpers.fmt_questions(query)]
    end)

    start = System.monotonic_time()

    register_before_send(conn, fn conn ->
      Logger.log(level, fn ->
        stop = System.monotonic_time()
        diff = System.convert_time_unit(stop - start, :native, :microsecond)

        [fmt_qr(not dns_message(query, :qr)), " in ", formatted_diff(diff)]
      end)

      conn
    end)
  end

  ###
  ### Priv
  ###
  defp fmt_qr(dns_message(qr: qr)), do: fmt_qr(qr)
  defp fmt_qr(false), do: "QUERY"
  defp fmt_qr(true), do: "ANSWER"

  defp formatted_diff(diff) when diff > 1000, do: [diff |> div(1000) |> Integer.to_string(), "ms"]
  defp formatted_diff(diff), do: [Integer.to_string(diff), "µs"]
end
