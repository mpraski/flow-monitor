defmodule FlowMonitor.Collector do
  use GenServer

  @timeres :millisecond

  defmodule State do
    defstruct time: 0,
              files: %{},
              counts: %{},
              config: %FlowMonitor.Config{}
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
    init(opts, %FlowMonitor.Config{})
  end

  def init([{:path, path} | opts], config) do
    init(opts, %FlowMonitor.Config{config | path: path})
  end

  def init([{:scopes, scopes} | opts], config) when is_list(scopes) do
    init(opts, %FlowMonitor.Config{config | scopes: scopes})
  end

  def init([{:name, name} | opts], config) do
    init(opts, %FlowMonitor.Config{config | graph_name: name})
  end

  def init([{:title, title} | opts], config) do
    init(opts, %FlowMonitor.Config{config | graph_title: title})
  end

  def init([{:size, {_, _} = size} | opts], config) do
    init(opts, %FlowMonitor.Config{config | graph_size: size})
  end

  def init([{:range, {_, _} = range} | opts], config) do
    init(opts, %FlowMonitor.Config{config | graph_range: range})
  end

  def init([{:font, font} | opts], config) do
    init(opts, %FlowMonitor.Config{config | font_name: font})
  end

  def init([{:font_size, font_size} | opts], config) do
    init(opts, %FlowMonitor.Config{config | font_size: font_size})
  end

  def init([{:xlabel, xlabel} | opts], config) do
    init(opts, %FlowMonitor.Config{config | xlabel: xlabel})
  end

  def init([{:ylabel, ylabel} | opts], config) do
    init(opts, %FlowMonitor.Config{config | ylabel: ylabel})
  end

  def init([_ | rest], config) do
    init(rest, config)
  end

  def init([], %FlowMonitor.Config{path: path, scopes: scopes, graph_name: name} = config) do
    files =
      scopes
      |> Stream.map(fn scope ->
        path = Path.join(path, "#{name}-#{scope}.log")

        {:ok, file} = :file.open(path, [:write, :raw])

        {scope, {path, file}}
      end)
      |> Map.new()

    time = :os.system_time(@timeres)

    files |> Enum.each(fn {_, {_, file}} -> write(file, time, 0) end)

    counts = scopes |> Stream.map(fn scope -> {scope, 0} end) |> Map.new()

    {:ok, %State{time: time, files: files, counts: counts, config: config}}
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

  def terminate(:normal, %State{config: config, files: files}) do
    FlowMonitor.Grapher.graph(config, prepare_files(files))
  end

  defp prepare_files(files) do
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
