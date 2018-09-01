defmodule FlowMonitor.Grapher do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def graph(path, files) do
    nil
  end
end
