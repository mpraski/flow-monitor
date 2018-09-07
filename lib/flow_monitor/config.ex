defmodule FlowMonitor.Config do
  @moduledoc """
  Struct representing configurable parameters of the generated graph.
  """

  defstruct path: ".",
            scopes: [],
            font_name: "Arial",
            font_size: 10,
            graph_name: "progress",
            graph_title: "Elixir Flow processing progress over time",
            graph_size: {700, 500},
            graph_range: {nil, nil},
            xlabel: "Time (ms)",
            ylabel: "Items processed",
            time_end: nil
end
