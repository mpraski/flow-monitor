defmodule FlowMonitor do
  defmacro run(pipeline, opts \\ []) do
    quote do
      %Flow{operations: operations} = flow = unquote(pipeline)

      names =
        1..length(operations)
        |> Stream.map(&Integer.to_string/1)
        |> Stream.map(&String.to_atom/1)
        |> Enum.to_list()

      {:ok, pid} = FlowMonitor.Collector.start_link(unquote(opts) |> Keyword.put(:scopes, names))

      {:ok, flow_pid} =
        %Flow{
          flow
          | operations:
              FlowMonitor.Inspector.inject_monitors(
                pid,
                operations,
                names
              )
        }
        |> Flow.start_link()

      flow_ref = Process.monitor(flow_pid)

      receive do
        {:DOWN, ^flow_ref, :process, ^flow_pid, :normal} ->
          FlowMonitor.Collector.stop(pid)
      end
    end
  end
end
