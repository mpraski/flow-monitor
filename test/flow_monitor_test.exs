defmodule FlowMonitorTest do
  use ExUnit.Case
  doctest FlowMonitor

  require FlowMonitor

  test "greets the world" do
    assert FlowMonitor.hello() == :world
  end

  def test_run do
    FlowMonitor.run(
      1..100
      |> Flow.from_enumerable()
      |> Flow.map(fn item -> item * 2 end)
      |> Flow.each(&IO.inspect/1)
    )
  end
end
