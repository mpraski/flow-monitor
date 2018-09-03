defmodule FlowMonitor.Supervisor do
  use Supervisor

  #############
  # Internals #
  #############

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    children = [
      {FlowMonitor.Grapher, []}
    ]

    opts = [strategy: :one_for_all]

    Supervisor.init(children, opts)
  end
end
