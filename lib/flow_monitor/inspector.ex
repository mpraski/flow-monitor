defmodule FlowMonitor.Inspector do
  # Collect stages' names via AST inspection, then simply start collector by
  # replacing operations with their augamented version

  @default_types [:map, :each]
  @mapper_types [:map, :each, :filter]

  defmodule NameAcc do
    defstruct depth: 0,
              max_depth: 10,
              lines: []
  end

  def extract_names({
        {
          :.,
          _,
          [{:__aliases__, _, [:Flow]}, type]
        },
        _,
        [mapper]
      }) do
    if type in @mapper_types do
      build_name(%NameAcc{}, mapper)
    else
      []
    end
  end

  def extract_names({_op, _meta, args}) do
    args |> Enum.map(&extract_names/1)
  end

  def extract_names(list) when is_list(list) do
    list |> Enum.map(&extract_names/1)
  end

  def extract_names(_) do
    []
  end

  defp build_name(
         %NameAcc{
           depth: depth,
           max_depth: max_depth
         } = acc,
         _args
       )
       when depth > max_depth do
    acc |> add("(...)")
  end

  defp build_name(acc, args) when not is_list(args) do
    build_name(acc, [args])
  end

  defp build_name(
         %NameAcc{
           depth: depth
         } = acc,
         args
       ) do
    args |> Enum.reduce(%NameAcc{acc | depth: depth + 1}, &build_name_segment/2)
  end

  defp build_name_segment({:&, _, [func]}, acc) do
    acc
    |> build_name(func)
    |> add("&")
  end

  defp build_name_segment({:/, _, [func, arity]}, acc) do
    acc
    |> add([arity, "/"])
    |> build_name(func)
  end

  defp build_name_segment({:., _, [namespace, id]}, acc) do
    acc
    |> build_name(id)
    |> add(".")
    |> build_name(namespace)
  end

  defp build_name_segment({:__aliases__, _, [sym]}, acc) do
    acc |> add(sym)
  end

  defp build_name_segment(sym, acc) when is_atom(sym) do
    acc |> add(sym)
  end

  defp build_name_segment({op, _, args}, acc) do
    acc
    |> build_name(op)
    |> build_name(args)
  end

  defp add(acc, elem) when not is_list(elem) do
    acc |> add([elem])
  end

  defp add(acc, []) do
    acc
  end

  defp add(%NameAcc{lines: lines} = acc, [elem | rest]) do
    %NameAcc{acc | lines: [elem | lines]} |> add(rest)
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
