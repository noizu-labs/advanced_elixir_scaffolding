defmodule Noizu.Scaffolding.V3.Sphinx.Integer do
  @moduledoc """
  Ecto ENUM Custom Type.
  """
  use Ecto.Type

  require Noizu.DomainObject
  Noizu.DomainObject.noizu_sphinx_handler()

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
      nil -> {:ok, 0}
      # special case for null encoding.
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
      v when is_integer(v) -> {:ok, v}
      true -> {:ok, 1}
      false -> {:ok, 0}
      _ -> raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect v}"
    end
  end
end
