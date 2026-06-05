defmodule JibbleBotTest do
  use ExUnit.Case
  doctest JibbleBot

  test "greets the world" do
    assert JibbleBot.hello() == :world
  end
end
