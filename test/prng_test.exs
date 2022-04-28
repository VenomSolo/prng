defmodule PrngTest do
  use ExUnit.Case
  doctest Prng

  test "greets the world" do
    assert Prng.hello() == :world
  end
end
