defmodule FlowMonitorTest do
  use ExUnit.Case
  doctest FlowMonitor

  require FlowMonitor

  test "greets the world" do
    assert FlowMonitor.hello() == :world
  end
end
