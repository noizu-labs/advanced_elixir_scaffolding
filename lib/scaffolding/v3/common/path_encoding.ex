#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.PathEncoding do
  @vsn 1.0
  @type t :: %__MODULE__{
               path: list,
               materialized_path: tuple,
               matrix: tuple,
               depth: integer,
               vsn: float
             }

  defstruct [
    path: nil,
    materialized_path: nil,
    matrix: nil,
    depth: 0,
    vsn: @vsn
  ]

  @identity_matrix %{
    a11: 1,
    a12: 0,
    a21: 0,
    a22: 1
  }

  def parent_path(nil), do: nil
  def parent_path(%{__struct__: __MODULE__} = this) do
    new(Enum.slice(this.path, 0..-2))
  end

  def path_string(nil), do: nil
  def path_string(%{__struct__: __MODULE__} = this) do
    Enum.join(this.path, ".")
  end

  #---------------------------
  #
  #---------------------------
  def position_matrix(position) when is_integer(position) do
    i = position + 1
    %{
      a11: i,
      a12: -1,
      a21: 1,
      a22: 0
    }
  end

  #---------------------------
  #
  #---------------------------
  def multiply_matrix(%{a11: a11, a12: a12, a21: a21, a22: a22}, %{a11: b11, a12: b12, a21: b21, a22: b22}) do
    %{
      a11: (a11 * b11 + a12 * b21),
      a12: (a11 * b12 + a12 * b22),
      a21: (a21 * b11 + a22 * b21),
      a22: (a21 * b12 + a22 * b22),
    }
  end

  #---------------------------
  #
  #---------------------------
  def leaf_node(%{a11: a11, a12: a12, a21: _a21, a22: _a22}) do
    Integer.floor_div(a11, -a12)
  end

  #---------------------------
  #
  #---------------------------
  def convert_path_to_matrix(path) when is_list(path) do
    Enum.reduce(
      path,
      @identity_matrix,
      fn (position, path) ->
        multiply_matrix(path, position_matrix(position))
      end
    )
  end


  #---------------------------
  #
  #---------------------------
  def convert_matrix_to_path(m) do
    convert_matrix_to_path(m, [])
  end

  def convert_matrix_to_path(%{a11: 1, a12: 0, a21: 0, a22: 1}, acc) do
    Enum.reverse(acc)
  end

  def convert_matrix_to_path(m, acc) do
    if (m.a22 == 0) do
      Enum.reverse(acc ++ [m.a11 - 1])
    else
      if (length(acc) < 12) do
        l = leaf_node(m)
        a11 = -m.a12
        a21 = -m.a22
        a12 = (m.a11 - (a11 * (l + 1)))
        a22 = (m.a21 - (a21 * (l + 1)))
        convert_matrix_to_path(%{a11: a11, a12: a12, a21: a21, a22: a22}, acc ++ [l])
      else
        {:error, acc}
      end
    end
  end

  #---------------------------
  #
  #---------------------------
  def convert_tuple_to_path(path) when is_tuple(path) do
    convert_tuple_to_path(path, [])
  end

  def convert_tuple_to_path({a}, acc), do: acc ++ [a]

  def convert_tuple_to_path({a, {}}, acc), do: acc ++ [a]

  def convert_tuple_to_path({a, b}, acc), do: convert_tuple_to_path(b, acc ++ [a])

  #---------------------------
  #
  #---------------------------
  def convert_path_to_tuple(path) when is_list(path) do
    path
    |> Enum.reverse()
    |> Enum.reduce({}, &({&1, &2}))
  end

  #---------------------------
  #
  #---------------------------
  def new(%{path_a11: a11, path_a12: a12, path_a21: a21, path_a22: a22}) do
    new(%{a11: a11, a12: a12, a21: a21, a22: a22})
  end

  def new(%{a11: a11, a12: a12, a21: a21, a22: a22} = _m) when a12 > 0 and a22 > 0 do
    new(%{a11: a11, a12: -a12, a21: a21, a22: -a22})
  end

  def new(%{a11: _a11, a12: _a12, a21: _a21, a22: _a22} = m)  do
    new(convert_matrix_to_path(m))
  end

  def new(path) when is_tuple(path) do
    new(convert_tuple_to_path(path))
  end

  def new(path) when is_list(path) do
    %__MODULE__{
      depth: length(path),
      path: path,
      materialized_path: convert_path_to_tuple(path),
      matrix: convert_path_to_matrix(path)
    }
  end

  #---------------------------
  # from_json
  #---------------------------
  def from_json(nil), do: nil
  def from_json(json) when is_list(json), do: new(json)
  def from_json(%{"path" => path}) when is_list(path), do: new(path)
  def from_json(%{"a11" => a11, "a12" => a12, "a21" => a21, "a22" => a22}) do
    case {a11, a12, a21, a22} do
      {a11, a12, a21, a22} when a12 > 0 and a22 > 0 -> new(%{a11: a11, a12: -a12, a21: a21, a22: -a22})
      {a11, a12, a21, a22} when a12 <= 0 and a22 <= 0 -> new(%{a11: a11, a12: a12, a21: a21, a22: a22})
    end
  end
  def from_json(json) when is_bitstring(json) do
    parse = json
            |> String.split(".")
            |> String.trim()
            |> Enum.reduce(
                 {:ok, []},
                 fn (n, {s, l}) ->
                   case Integer.parse(n) do
                     {:ok, i} -> {s, l ++ [i]}
                     _ -> {:error, l}
                   end
                 end
               )
    case parse do
      {:ok, []} -> nil
      {:ok, path} -> new(path)
      error -> error
    end
  end
  def from_json(_), do: {:error, :invalid_json}

  def vsn(), do: @vsn
end
