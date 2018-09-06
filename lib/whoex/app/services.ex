# Bootstrap the module with empty list
defmodule Whoex.App.ServicesSpecs do
  def specs, do: []
end

defmodule Whoex.App.Services do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Whoex.App.Services

      Services.define([])
    end
  end

  def specs, do: Whoex.App.ServicesSpecs.specs()

  defmacro define(specs) do
    quote do
      _ = Code.compiler_options(ignore_module_conflict: true)

      defmodule Elixir.Whoex.App.ServicesSpecs do
        @specs unquote(specs)
        def specs, do: @specs
      end

      _ = Code.compiler_options(ignore_module_conflict: false)
    end
  end
end
