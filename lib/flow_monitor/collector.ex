defmodule FlowMonitor.Collector do
  use GenServer

  @timeres :millisecond

  defmodule Config do
    defstruct name: "progress",
              path: ".",
              scopes: []
  end

  defmodule State do
    defstruct time: 0,
              path: "",
              files: %{},
              counts: %{}
  end

  ##############
  # Public API #
  ##############
  def incr(pid, scope, amount \\ 1) do
    GenServer.cast(pid, {:incr, scope, amount})
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  #############
  # Internals #
  #############

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    init(opts, %Config{})
  end

  def init([{:name, name} | opts], config) when is_bitstring(name) do
    init(opts, %Config{config | name: name})
  end

  def init([{:path, path} | opts], config) when is_bitstring(path) do
    init(opts, %Config{config | path: path})
  end

  def init([{:scopes, scopes} | opts], config) when is_list(scopes) do
    init(opts, %Config{config | scopes: scopes})
  end

  def init([_ | rest], config) do
    init(rest, config)
  end

  def init([], %Config{name: name, path: path, scopes: scopes}) do
    files =
      scopes
      |> Stream.map(fn scope ->
        path = "#{path}/#{name}-#{scope}.log"

        {:ok, file} = :file.open(path, [:write, :raw])

        {scope, {path, file}}
      end)
      |> Map.new()

    time = :os.system_time(@timeres)

    files |> Enum.each(fn {_, {_, file}} -> write(file, time, 0) end)

    counts = scopes |> Stream.map(fn scope -> {scope, 0} end) |> Map.new()

    {:ok, %State{time: time, path: path, files: files, counts: counts}}
  end

  def handle_cast(
        {:incr, scope, amount},
        %State{
          time: time,
          files: files,
          counts: counts
        } = state
      ) do
    {count, counts} = counts |> Map.get_and_update!(scope, &{&1 + amount, &1 + amount})

    %{^scope => {_path, file}} = files

    write(file, time, count)

    {:noreply, %State{state | counts: counts}}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, %State{files: files, path: path}) do
    FlowMonitor.Grapher.graph(path, prepare_data(files))
  end

  defp prepare_data(files) do
    files
    |> Stream.each(fn {_, {_, file}} -> :file.close(file) end)
    |> Stream.map(fn {scope, {path, _}} -> {scope, path} end)
    |> Enum.to_list()
  end

  defp write(file, time, amount) do
    time = :os.system_time(@timeres) - time
    :file.write(file, "#{time}\t#{amount}\n")
  end
end
