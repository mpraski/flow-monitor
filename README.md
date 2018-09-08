# Flow Monitor

## What is it?

Elixir macro for measuring progress of steps in a [Flow](https://hexdocs.pm/flow/Flow.html) pipeline.

## Installation

Add `flow_monitor` as a dependency in your `mix.exs` file.

```elixir
defp deps do
  [
     # ...
    {:flow_monitor, "~> x.x.x"},
  ]
end
```

Where `x.x.x` equals the version in [`mix.exs`](mix.exs).

Afterwards run `mix deps.get` in your command line to fetch the dependency.

## Usage

#### `FlowMonitor.run/2`

Runs the metrics collector on a given `Flow` pipeline.
Results are store in a directory `{graph_name}-{timestamp}` in a given path.
See `FlowMonitor.Config` for configurable options which can be passed as keyword list `opts`.

## Examples

#### Specify path for collected metrics, name and title

```elixir
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
```

#### Specify other graph parameters

```elixir
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
```

## To-Do

 - Add tests