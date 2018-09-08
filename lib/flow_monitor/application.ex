defmodule FlowMonitor.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {FlowMonitor.Grapher, []}
    ]

    opts = [strategy: :one_for_one, name: FlowMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
