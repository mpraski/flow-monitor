defmodule FlowMonitorTest do
  use ExUnit.Case
  doctest FlowMonitor

  test "greets the world" do
    assert FlowMonitor.hello() == :world
  end
end
