defmodule FlowMonitor.Inspector do
  # Collect stages' names via AST inspection, then simply start collector by
  # replacing operations with their augamented version

  @default_types [:map, :each]

  def find_names({
        {
          :.,
          _,
          [{[:Flow]}, :map]
        },
        _,
        [mapper]
      }) do
  end

  def find_names({_op, _meta, args}) do
    args |> Enum.each(&find_names/1)
  end

  def extract_name({:&, [], [{:*, [context: Elixir, import: Kernel], [{:&, [], [1]}, 2]}]}) do
  end

  def extract_anonymous_func() do
  end

  def inject_monitors(pid, operations, names, types \\ @default_types) do
    [
      operations,
      names
    ]
    |> Stream.zip()
    |> Stream.map(fn {{:mapper, type, [func]} = mapper, name} ->
      if type in types do
        {:mapper, type,
         [
           fn item ->
             result = func.(item)
             FlowMonitor.Collector.incr(pid, name)
             result
           end
         ]}
      else
        mapper
      end
    end)
    |> Enum.to_list()
  end
end
