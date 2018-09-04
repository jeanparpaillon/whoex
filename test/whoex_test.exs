defmodule WhoexTest do
  use ExUnit.Case
  doctest Whoex

  test "greets the world" do
    assert Whoex.hello() == :world
  end
end
