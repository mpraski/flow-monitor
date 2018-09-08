defmodule FlowMonitor do
  @moduledoc """
  Measure progress of each step in a Flow pipeline.
  """

  alias FlowMonitor.{Collector, Inspector}

  @doc """
  Runs the metrics collector on a given Flow pipeline.
  Results are store in a directory `{graph_name}-{timestamp}` in a given path.
  See `FlowMonitor.Config` for configurable options which can be passed as keyword list `opts`.

  ## Examples:

  #### Specify path for collected metrics, name and title
      opts = [
        path: "./metrics",
        graph_name: "collected-metrics",
        graph_title: "Metrics collected from a Flow execution"
      ]

      FlowMonitor.run(
        1..100_000
        |> Flow.from_enumerable()
        |> Flow.map(&(&1 * &1)),

        opts
      )

  #### Specify other graph parameters
      opts = [
        font_name: "Verdana",
        font_size: 12,
        graph_size: {800, 600},
        graph_range: {1000, 15000}
      ]

      FlowMonitor.run(
        1..100_000
        |> Flow.from_enumerable()
        |> Flow.map(&(&1 * &1)),

        opts
      )
  """
  @spec run(any(), keyword()) :: any()
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

  @doc false
  @spec start_flow(Flow.t(), [String.t()], keyword()) :: {pid(), reference(), pid()}
  def start_flow(%Flow{} = flow, names, opts) do
    scopes = Inspector.extract_producer_names(flow) ++ names

    {:ok, collector_pid} = Collector.start_link(opts |> Keyword.put(:scopes, scopes))

    {:ok, flow_pid} =
      flow
      |> FlowMonitor.inject(collector_pid, names)
      |> Flow.start_link()

    flow_ref = Process.monitor(flow_pid)

    {flow_pid, flow_ref, collector_pid}
  end

  @doc false
  @spec inject(Flow.t(), pid(), [String.t()]) :: Flow.t()
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
