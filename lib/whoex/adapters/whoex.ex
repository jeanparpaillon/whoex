defmodule Whoex.Adapters.Whoex do
  @moduledoc """
  Adapter interface for the integrated DNS server

  ## Options

    * `:ip` - the ip to bind the serve to.
      `{a, b, c, d}` with each value in `0..255` for IPv4
      or `{a, b, c, d, e, f, g, h}` with each value in `0..65535` for IPv6.

    * `:port` - the port to run the server.
      Defaults to 53
  """

  @doc """
  A function for starting the Whoex server under Elixir v1.5 supervisors.

  It expects two options:

    * `:plug` - such as MyPlug or {MyPlug, plug_opts}
    * `:options` - the server options as specified in the module documentation

  ## Examples

  Assuming your Plug module is named `MyApp` you can add it to your
  supervision tree by using this function:

      children = [
        {Whoex.Adapters.Whoex, plug: MyApp, options: [port: 10053]}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)

  """
  defdelegate child_spec(options), to: Whoex.Server
end
