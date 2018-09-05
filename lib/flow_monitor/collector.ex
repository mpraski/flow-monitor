defmodule FlowMonitor.Collector do
  use GenServer

  alias FlowMonitor.{Grapher, Config}

  @timeres :millisecond
  @time_margin 2

  defmodule State do
    defstruct time: 0,
              files: %{},
              counts: %{},
              config: %Config{}
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

  def init([{:path, path} | opts], config) do
    init(opts, %Config{config | path: path})
  end

  def init([{:scopes, scopes} | opts], config) when is_list(scopes) do
    init(opts, %Config{config | scopes: scopes})
  end

  def init([{:name, name} | opts], config) do
    init(opts, %Config{config | graph_name: name})
  end

  def init([{:title, title} | opts], config) do
    init(opts, %Config{config | graph_title: title})
  end

  def init([{:size, {_, _} = size} | opts], config) do
    init(opts, %Config{config | graph_size: size})
  end

  def init([{:range, {_, _} = range} | opts], config) do
    init(opts, %Config{config | graph_range: range})
  end

  def init([{:font, font} | opts], config) do
    init(opts, %Config{config | font_name: font})
  end

  def init([{:font_size, font_size} | opts], config) do
    init(opts, %Config{config | font_size: font_size})
  end

  def init([{:xlabel, xlabel} | opts], config) do
    init(opts, %Config{config | xlabel: xlabel})
  end

  def init([{:ylabel, ylabel} | opts], config) do
    init(opts, %Config{config | ylabel: ylabel})
  end

  def init([_ | rest], config) do
    init(rest, config)
  end

  def init([], %Config{path: path, scopes: scopes, graph_name: name} = config) do
    dir = Path.join(path, "#{name}-#{safe_time()}")

    :file.make_dir(dir)

    files =
      scopes
      |> Enum.map(fn scope ->
        scope_safe = scope |> safe_filename()

        path = Path.join(dir, "#{name}-#{scope_safe}.log")

        {:ok, file} = :file.open(path, [:write, :raw])

        {scope, {path, file}}
      end)

    time = :os.system_time(@timeres)

    files |> Enum.each(fn {_, {_, file}} -> write(file, time, 0) end)

    counts = scopes |> Stream.map(fn scope -> {scope, 0} end) |> Map.new()

    {:ok, %State{time: time, files: files, counts: counts, config: %Config{config | path: dir}}}
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

    {_path, file} = files |> Keyword.get(scope)

    write(file, time, count)

    {:noreply, %State{state | counts: counts}}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(:normal, %State{config: config, files: files, time: time}) do
    Grapher.graph(
      %Config{
        config
        | time_end: :os.system_time(@timeres) - time + @time_margin
      },
      prepare_files(files)
    )
  end

  defp prepare_files(files) do
    files
    |> Stream.each(fn {_, {_, file}} -> :file.close(file) end)
    |> Stream.map(fn {scope, {path, _}} ->
      {
        safe_title(scope),
        path
      }
    end)
    |> Enum.to_list()
  end

  defp write(file, time, amount) do
    time = :os.system_time(@timeres) - time
    :file.write(file, "#{time}\t#{amount}\n")
  end

  defp safe_filename(scope) do
    scope
    |> Atom.to_string()
    |> String.replace(~r/(#|-|>|,|\.|&|\/|:|\s)/, "")
    |> String.downcase()
  end

  defp safe_title(scope) do
    scope
    |> Atom.to_string()
    |> String.replace("&", ~s(\\\\\&))
  end

  defp safe_time() do
    DateTime.utc_now() |> DateTime.to_unix()
  end
end
