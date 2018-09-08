defmodule FlowMonitor.Config do
  @moduledoc """
  Struct representing configurable parameters of graph generation. These include:

  Option | Description | Default value
  --- | --- | ---
  `path` | relative location of generated metrics files and image | `"./"`
  `font_name` | font name used by gnuplot | `"Arial"`
  `font_size` | font size used by gnuplot | `10`
  `graph_name` | the name of the generated graph, as well as the prefix of containing directory and metrics files | `"progress"`
  `graph_title` | the title of the graph | `"Elixir Flow processing progress over time"`
  `graph_size` | the width and height of resulting image | `{700, 500}`
  `graph_range` | horizontal range of the graph | `{0, length of flow execution (millseconds)}`
  `xlabel` | x label of the graph | `"Time (ms)"`
  `ylabel` | y label of the graph | `"Items processed"`
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
