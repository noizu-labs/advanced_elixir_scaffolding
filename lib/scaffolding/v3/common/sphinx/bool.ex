defmodule Noizu.Scaffolding.V3.Sphinx.Bool do
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
      0 -> {:ok, false}
      "false" -> {:ok, false}
      v -> {:ok, v && true || false}
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
      0 -> {:ok, false}
      v -> {:ok, v && true || false}
    end
  end

  #----------------------------
  # load
  #----------------------------
  def load(v) do
    case v do
      0 -> {:ok, false}
      "false" -> {:ok, false}
      v -> {:ok, v && true || false}
    end
  end
end
