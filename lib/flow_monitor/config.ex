defmodule FlowMonitor.Config do
  defstruct path: ".",
            scopes: [],
            font_name: "Arial",
            font_size: 10,
            graph_name: "progress",
            graph_title: "Elixir Flow processing progress over time",
            graph_size: {700, 500},
            graph_range: {0, nil},
            xlabel: "Time (ms)",
            ylabel: "Items processed",
            time_end: nil
end
