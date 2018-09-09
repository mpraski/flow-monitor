defmodule InspectorTest do
  use ExUnit.Case

  alias FlowMonitor.Inspector

  test "recognizes different mapper types" do
    code = [
      map: quote(do: Flow.map(&(&1 / 10))),
      each: quote(do: Flow.each(&(&1 / 10))),
      filter: quote(do: Flow.filter(&(&1 / 10))),
      flat_map: quote(do: Flow.flat_map(&(&1 / 10)))
    ]

    code
    |> Enum.each(fn {type, snippet} ->
      [representation] = Inspector.extract_names(snippet)
      assert String.starts_with?(representation, Helpers.atom_capitalize(type))
    end)
  end

  test "returns empty list for irrelevant flow definition" do
    code = quote do: Flow.partition(max_demand: 5, stages: 5)

    assert Inspector.extract_names(code) == []
  end

  test "correctly represents fn [args] -> ... end expressions" do
    code = quote do: Flow.map(fn item -> item * 2 end)
    representation = "Map (fn item -> ... end)"

    assert Inspector.extract_names(code) == [representation]
  end

  test "correctly represents &(&1 / 10) expressions" do
    code = quote do: Flow.map(&(&1 / 10))
    representation = "Map (&(&1 / 10))"

    assert Inspector.extract_names(code) == [representation]
  end

  test "correctly represents &func(&1) expressions" do
    code = quote do: Flow.map(&func(&1))
    representation = "Map (&func(&1))"

    assert Inspector.extract_names(code) == [representation]
  end

  test "correctly represents &func(&1, term, term2) expressions" do
    code = quote do: Flow.map(&func(&1, term, term2))
    representation = "Map (&func(&1, term, term2))"

    assert Inspector.extract_names(code) == [representation]
  end

  test "correctly represents some.nested.reference expressions" do
    code = quote do: Flow.map(some.nested.reference)
    representation = "Map (some.nested.reference)"

    assert Inspector.extract_names(code) == [representation]
  end

  test "correctly represents &IO.inspect/1 expressions" do
    code = quote do: Flow.map(&IO.inspect/1)
    representation = "Map (&IO.inspect/1)"

    assert Inspector.extract_names(code) == [representation]
  end

  test "returns an empty producer list for irrelevant flow definition" do
    flow = %Flow{} |> Flow.partition(max_demand: 5, stages: 5)

    assert Inspector.extract_producer_names(flow) == []
  end

  test "correctly extract single producer from pipeline" do
    flow = 1..100_000 |> Flow.from_enumerable()
    producer = :"Enumerable 1"

    assert Inspector.extract_producer_names(flow) == [producer]
  end

  test "correctly extract multiple producers from pipeline" do
    streams =
      for i <- 1..10 do
        i..(i * 10)
      end

    flow = streams |> Flow.from_enumerables()
    producers = Helpers.n_atoms("Enumerable", 10, 1)

    assert Inspector.extract_producer_names(flow) == producers
  end
end
