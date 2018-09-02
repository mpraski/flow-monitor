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

  def stop_collector(pid) do
    GenServer.cast(__MODULE__, {:stop_collector, pid})
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

  def handle_cast({:stop_collector, pid}, state) do
    FlowMonitor.CollectorSupervisor.stop_collector(pid)
    {:noreply, state}
  end
end
