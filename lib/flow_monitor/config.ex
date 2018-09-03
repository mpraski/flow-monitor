defmodule FlowMonitor.Config do
  defstruct path: ".",
            scopes: [],
            font_name: "Arial",
            font_size: 10,
            graph_name: "progress",
            graph_title: "Elixir Flow processing progress over time",
            graph_size: {700, 500},
            graph_range: {0, 15_000},
            xlabel: "Time (ms)",
            ylabel: "Items processed"
end
