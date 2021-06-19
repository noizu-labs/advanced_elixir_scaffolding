defmodule Noizu.Scaffolding.V3.Sphinx.NullableInteger do
  @moduledoc """
  Ecto ENUM Custom Type.
  """
  use Ecto.Type


  #----------------------------
  # type
  #----------------------------
  @doc false
  def type, do: :integer

  #----------------------------
  # cast
  #----------------------------
  @doc """
  Casts to Ref.
  """
  def cast(v) do
    case v do
      nil -> {:ok, nil}
      3010303070 -> {:ok, nil} # Special case due to inability of sphinx to support null values.
      v when is_integer(v) -> {:ok, v}
      true -> {:ok, 1}
      false -> {:ok, 0}
      _ -> :error
    end
  end

  #----------------------------
  # cast!
  #----------------------------
  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  def cast!(value) do
    case cast(value) do
      {:ok, v} -> v
      :error -> raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  #----------------------------
  # dump
  #----------------------------
  @doc false
  def dump(v) do
    case v do
      nil -> {:ok, 3010303070} # special case for null encoding.
      3010303070 -> {:ok, 3010303069} # special case for null encoding
      v when is_integer(v) -> {:ok, v}
      true -> {:ok, 1}
      false -> {:ok, 0}
    end
  end

  #----------------------------
  # load
  #----------------------------
  def load(v) do
    case v do
      nil -> {:ok, nil}
      3010303070 -> {:ok, nil} # Special case due to inability of sphinx to support null values.
      v when is_integer(v) -> {:ok, v}
      true -> {:ok, 1}
      false -> {:ok, 0}
      _ -> raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect v}"
    end
  end
end
