defmodule FlowMonitor.Dispatcher do
  use GenServer

  defmodule State do
    defstruct collectors: []
  end

  ##############
  # Public API #
  ##############
  def start_collector(opts) do
    GenServer.call(__MODULE__, {:start_collector, opts})
  end

  #############
  # Internals #
  #############
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    {:ok, %State{collectors: []}}
  end

  def handle_call({:start_collector, opts}, _from, %State{collectors: collectors} = state) do
    {:ok, pid} = FlowMonitor.CollectorSupervisor.start_collector(opts)
    {:reply, pid, %State{state | collectors: [pid | collectors]}}
  end
end
