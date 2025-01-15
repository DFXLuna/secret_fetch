defmodule SecretFetchTest do
  use ExUnit.Case
  doctest SecretFetch

  test "greets the world" do
    assert SecretFetch.hello() == :world
  end
end
