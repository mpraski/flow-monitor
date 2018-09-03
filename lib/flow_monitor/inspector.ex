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

  defp build_name(
         %NameAcc{
           depth: depth,
           max_depth: max_depth
         } = acc,
         _args
       )
       when depth > max_depth do
    acc
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
    |> add("&")
    |> build_name(func)
  end

  defp build_name_segment({:/, _, [func, arity]}, acc) do
    acc
    |> build_name(func)
    |> add_at_end(["/", arity])
  end

  defp build_name_segment({:., _, [namespace, id]}, acc) do
    acc
    |> build_name(namespace)
    |> add(".")
    |> build_name(id)
  end

  defp build_name_segment({:__aliases__, _, [sym]}, acc) do
    acc |> add(sym)
  end

  defp build_name_segment(sym, acc) do
    acc |> add(sym)
  end

  defp add(acc, elem) when not is_list(elem) do
    add(acc, [elem])
  end

  defp add(acc, []) do
    acc
  end

  defp add(%NameAcc{lines: lines} = acc, [elem | rest]) do
    add(%NameAcc{acc | lines: [elem | lines]}, rest)
  end

  defp add_at_end(%NameAcc{lines: lines} = acc, elems) when is_list(elems) do
    %NameAcc{acc | lines: lines ++ elems}
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
