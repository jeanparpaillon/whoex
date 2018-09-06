defmodule Whoex.App do
  @moduledoc """
  Manages services required by different plugs

  Services are defined at compile-time through the use of plugs
  """
  use Application
  use Whoex.App.Services

  @doc false
  def start(_type, _args) do
    Supervisor.start_link(Services.specs(), strategy: :one_for_one)
  end

  @doc """
  Declares a child spec to be started as part of supervision tree
  """
  def add_child(spec) do
    specs = Services.specs() ++ [spec]

    specs
    |> Enum.uniq()
    |> Services.define()
  end
end
