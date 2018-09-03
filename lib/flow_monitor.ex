defmodule FlowMonitor do
  defmacro run(pipeline, opts \\ []) do
    extracted_names =
      FlowMonitor.Inspector.extract_names(pipeline)
      |> Enum.map(&String.to_atom/1)

    quote do
      names = unquote(extracted_names)

      %Flow{operations: operations} = flow = unquote(pipeline)

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
