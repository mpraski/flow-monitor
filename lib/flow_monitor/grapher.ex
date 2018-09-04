defmodule FlowMonitor.Grapher do
  use GenServer

  @plot_file "plot.gp"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def graph(%FlowMonitor.Config{} = config, files) when is_list(files) do
    GenServer.cast(__MODULE__, {:graph, config, files})
  end

  def handle_cast({:graph, config, files}, state) do
    File.write(Path.join([config.path, @plot_file]), build_graph(config, files))

    if System.find_executable("gnuplot") do
      System.cmd("gnuplot", [@plot_file])
    end

    {:noreply, state}
  end

  defp build_graph(
         %FlowMonitor.Config{
           path: path,
           font_name: font_name,
           font_size: font_size,
           graph_name: graph_name,
           graph_title: graph_title,
           graph_size: {width, height},
           graph_range: {rstart, rend},
           xlabel: xlabel,
           ylabel: ylabel,
           time_end: time_end
         },
         files
       ) do
    """
    set terminal png font "#{font_name},#{font_size}" size #{width},#{height}
    set output "#{path}/#{graph_name}.png"

    set title "#{graph_title}"
    set xlabel "#{xlabel}"
    set ylabel "#{ylabel}"
    set key top left

    set xrange [#{
      if rstart do
        rstart
      else
        0
      end
    }:#{
      if rend do
        rend
      else
        time_end
      end
    }]

    plot #{
      files
      |> Stream.with_index(1)
      |> Stream.map(fn {{scope, path}, index} ->
        "\"#{path}\" with steps ls #{index} title \"#{scope}\","
      end)
      |> Enum.join()
    }
    """
  end
end
