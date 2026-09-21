defmodule CraftChatTest do
  use ExUnit.Case
  doctest CraftChat

  test "greets the world" do
    assert CraftChat.hello() == :world
  end
end
