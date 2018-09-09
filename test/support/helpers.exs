defmodule Helpers do
  def atom_capitalize(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.capitalize()
  end

  def n_atoms(template, count, index) do
    1..count
    |> Stream.with_index(index)
    |> Stream.map(fn {_, index} ->
      :"#{template} #{index}"
    end)
    |> Enum.to_list()
  end
end
