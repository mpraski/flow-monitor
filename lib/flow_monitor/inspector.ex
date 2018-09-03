defmodule FlowMonitor.Inspector do
  # Collect stages' names via AST inspection, then simply start collector by
  # replacing operations with their augamented version

  @default_types [:map, :each]

  defmodule NameAcc do
    defstruct depth: 0,
              max_depth: 3,
              lines: []
  end

  def extract_names({
        {
          :.,
          _,
          [{[:Flow]}, :map]
        },
        _,
        [mapper]
      }) do
    build_name(%NameAcc{}, mapper)
  end

  def extract_names({_op, _meta, args}) do
    args |> Enum.each(&extract_names/1)
  end

  def build_name(
        %NameAcc{
          depth: depth,
          max_depth: max_depth
        } = acc,
        _args
      )
      when depth > max_depth do
    acc
  end

  def build_name(
        %NameAcc{
          depth: depth
        } = acc,
        args
      ) do
    args |> Enum.reduce(%NameAcc{acc | depth: depth + 1}, &build_name_segment/2)
  end

  def build_name_segment({:&, _, [func]}, %NameAcc{lines: lines} = acc) do
    build_name(%NameAcc{acc | lines: ["&" | lines]}, [func])
  end

  def build_name_segment({:/, _, [func, arity]}, %NameAcc{lines: lines} = acc) do
    %NameAcc{lines: newlines} = newacc = build_name(%NameAcc{acc | lines: ["/" | lines]}, [func])
    %NameAcc{newacc | lines: newlines ++ ["/", arity]}
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
