defmodule FlowMonitor.Inspector do
  @moduledoc false

  alias FlowMonitor.Collector

  @mapper_types [:map, :flat_map, :each, :filter]
  @binary_operators [
    :+,
    :-,
    :*,
    :++,
    :--,
    :..,
    :<>,
    :in,
    :"not in",
    :|>,
    :<<<,
    :>>>,
    :~>>,
    :<<~,
    :~>,
    :<~,
    :<~>,
    :<|>,
    :<,
    :>,
    :<=,
    :>=,
    :==,
    :!=,
    :=~,
    :===,
    :!==,
    :&&,
    :&&&,
    :and,
    :||,
    :|||,
    :or,
    :=,
    :|,
    :::,
    :when,
    :<-,
    :\\,
    :/
  ]

  defmodule NameAcc do
    @moduledoc false

    defstruct depth: 0,
              max_depth: 10,
              lines: []

    def new, do: %__MODULE__{}

    def from(%__MODULE__{depth: depth, max_depth: max_depth}) do
      %__MODULE__{depth: depth, max_depth: max_depth}
    end
  end

  @spec extract_names(any()) :: [String.t()]
  def extract_names(pipeline) do
    pipeline
    |> extract_names([])
    |> Enum.reverse()
  end

  defp extract_names(
         {
           {
             :.,
             _,
             [{:__aliases__, _, [:Flow]}, type]
           },
           _,
           [mapper]
         },
         acc
       )
       when type in @mapper_types do
    formatted_type =
      type
      |> Atom.to_string()
      |> String.capitalize()

    [
      NameAcc.new()
      |> add(")")
      |> build_name(mapper)
      |> add("#{formatted_type} (")
      |> to_text()
      | acc
    ]
  end

  defp extract_names({_op, _meta, args}, acc) do
    args |> extract_names(acc)
  end

  defp extract_names(args, acc) when is_list(args) do
    args |> Enum.reduce(acc, &extract_names/2)
  end

  defp extract_names(_, acc), do: acc

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

  defp build_name(
         %NameAcc{
           depth: depth
         } = acc,
         args
       ) do
    args
    |> to_list()
    |> Enum.reduce(%NameAcc{acc | depth: depth + 1}, &build_name_segment/2)
  end

  defp build_name_segment({:&, _, [arg]}, acc) do
    acc
    |> build_name(arg)
    |> add("&")
  end

  defp build_name_segment({:/, _, [{{:., _, _}, _, _} = dot_access, arity]}, acc) do
    acc
    |> add(arity)
    |> add("/")
    |> build_name(dot_access)
  end

  defp build_name_segment({:/, _, [{func, _, Elixir}, arity]}, acc) do
    acc
    |> add(arity)
    |> add("/")
    |> build_name(func)
  end

  defp build_name_segment({:., _, [namespace, id]}, acc) do
    acc
    |> build_name(id)
    |> add(".")
    |> build_name(namespace)
  end

  defp build_name_segment({:fn, _, [arrow]}, acc) do
    acc
    |> build_name(arrow)
    |> add("fn ")
  end

  defp build_name_segment({:->, _, [args, _]}, acc) do
    formatted_args =
      args
      |> Stream.map(fn {arg, _, _} -> arg end)
      |> Stream.intersperse(", ")
      |> Enum.reverse()

    acc
    |> add(" -> ... end")
    |> add(formatted_args)
  end

  defp build_name_segment({:__aliases__, _, [sym]}, acc) do
    acc |> add(sym)
  end

  defp build_name_segment({term, _, namespace}, acc) when is_atom(namespace) do
    acc |> add(term)
  end

  defp build_name_segment({op, _, [_, _] = args}, acc) when op in @binary_operators do
    formatted_call =
      args
      |> Stream.map(fn arg ->
        NameAcc.from(acc)
        |> build_name(arg)
        |> to_text()
      end)
      |> Stream.intersperse(" #{op} ")
      |> Enum.join()

    acc
    |> add(")")
    |> add(formatted_call)
    |> add("(")
  end

  defp build_name_segment({op, _, args}, acc) do
    formatted_args =
      args
      |> Stream.map(fn arg ->
        NameAcc.from(acc)
        |> build_name(arg)
        |> to_text()
      end)
      |> Stream.intersperse(", ")
      |> Enum.join()

    acc =
      if String.length(formatted_args) === 0 do
        acc
      else
        acc
        |> add(")")
        |> add(formatted_args)
        |> add("(")
      end

    acc |> build_name(op)
  end

  defp build_name_segment(sym, acc) do
    acc |> add(sym)
  end

  defp add(acc, elem) when not is_list(elem) do
    acc |> add([elem])
  end

  defp add(acc, []), do: acc

  defp add(%NameAcc{lines: lines} = acc, [elem | rest]) do
    %NameAcc{acc | lines: [elem | lines]} |> add(rest)
  end

  defp to_text(%NameAcc{lines: lines}) do
    lines |> Enum.join()
  end

  defp to_list(items) when not is_list(items) do
    [items]
  end

  defp to_list(items), do: items

  @spec extract_producer_names(Flow.t()) :: [String.t()]
  def extract_producer_names(%Flow{producers: producers}) do
    case producers do
      {:enumerables, enumerables} ->
        enumerables
        |> Stream.with_index(1)
        |> Stream.map(fn {_, index} -> enumerable_name(index) end)
        |> Enum.to_list()

      _ ->
        []
    end
  end

  defp enumerable_name(index) do
    :"Enumerable #{index}"
  end

  @spec inject_monitors(pid(), any(), [String.t()], [atom()]) :: [any()]
  def inject_monitors(pid, operations, names, types \\ @mapper_types) do
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
             Collector.incr(pid, name)
             result
           end
         ]}
      else
        mapper
      end
    end)
    |> Enum.to_list()
  end

  @spec inject_enumerable_monitors(pid(), any()) :: [String.t()]
  def inject_enumerable_monitors(pid, enumerables) do
    enumerables
    |> Stream.with_index(1)
    |> Stream.map(fn {enum, index} ->
      enum
      |> Stream.each(fn _ ->
        Collector.incr(pid, enumerable_name(index))
      end)
    end)
    |> Enum.to_list()
  end
end
