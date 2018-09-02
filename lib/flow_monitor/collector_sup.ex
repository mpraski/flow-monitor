defmodule FlowMonitor.CollectorSupervisor do
  use DynamicSupervisor

  ##############
  # Public API #
  ##############
  def start_collector(collector_opts \\ []) do
    DynamicSupervisor.start_child(__MODULE__, {FlowMonitor.Collector, collector_opts})
  end

  def stop_collector(collector_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, collector_pid)
  end

  #############
  # Internals #
  #############
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
