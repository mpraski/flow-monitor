defmodule FlowMonitor do
  @moduledoc """
  Measure progress of each step in a Flow pipeline
  """

  alias FlowMonitor.{Collector, Inspector}

  defmacro run(pipeline, opts \\ []) do
    names =
      pipeline
      |> Inspector.extract_names()
      |> Enum.map(&String.to_atom/1)

    quote do
      {flow_pid, flow_ref, collector_pid} =
        FlowMonitor.start_flow(unquote(pipeline), unquote(names), unquote(opts))

      receive do
        {:DOWN, ^flow_ref, :process, ^flow_pid, :normal} ->
          Collector.stop(collector_pid)
      end
    end
  end

  def start_flow(%Flow{} = flow, names, opts) do
    enumerable_names = flow |> Inspector.extract_producer_names()

    scopes = enumerable_names ++ names

    {:ok, collector_pid} = Collector.start_link(opts |> Keyword.put(:scopes, scopes))

    {:ok, flow_pid} =
      flow
      |> FlowMonitor.inject(collector_pid, names)
      |> Flow.start_link()

    flow_ref = Process.monitor(flow_pid)

    {flow_pid, flow_ref, collector_pid}
  end

  def inject(
        %Flow{
          operations: operations,
          producers: producers
        } = flow,
        pid,
        names
      ) do
    flow = %Flow{
      flow
      | operations:
          Inspector.inject_monitors(
            pid,
            operations,
            names
          )
    }

    case producers do
      {:enumerables, enumerables} ->
        %Flow{
          flow
          | producers: {:enumerables, Inspector.inject_enumerable_monitors(pid, enumerables)}
        }

      _ ->
        flow
    end
  end
end
