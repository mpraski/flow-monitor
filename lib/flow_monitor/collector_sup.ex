defmodule FlowMonitor.CollectorSupervisor do
  use DynamicSupervisor

  ##############
  # Public API #
  ##############
  def start_collector(collector_opts \\ []) do
    DynamicSupervisor.start_child(__MODULE__, {FlowMonitor.Collector, collector_opts})
  end

  #############
  # Internals #
  #############
  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
