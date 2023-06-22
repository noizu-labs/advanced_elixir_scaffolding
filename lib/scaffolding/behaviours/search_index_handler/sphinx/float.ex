#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Sphinx.Type.Float do
  @moduledoc """
  Encode/Decode Float value for Sphinx Database.
  """
  use Ecto.Type

  require Noizu.DomainObject
  Noizu.DomainObject.noizu_sphinx_handler()

  #----------------------------
  # type
  #----------------------------
  @doc false
  def type, do: :float

  #----------------------------
  # cast
  #----------------------------
  @doc """
  Casts to Ref.
  """
  def cast(v) do
    case v do
      nil -> {:ok, nil}
      -9999.513672 -> {:ok, nil}
      # Special case due to inability of sphinx to support null values.
      v when is_integer(v) -> {:ok, v + 0.0}
      v when is_float(v) -> {:ok, v}
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
  @doc """
  Encode the input value to a compatible format for storing in Sphinx Database.
  """
  def dump(v) do
    case v do
      nil -> {:ok, -9999.513672}
      # special case for null encoding.
      -9999.513672 -> {:ok, -9999.513671}
      # special case for null encoding
      v when is_integer(v) -> {:ok, v + 0.0}
      v when is_float(v) -> {:ok, v}
      %Decimal{} -> dump(Decimal.to_float(v))
      _ -> :error
    end
  end

  #----------------------------
  # load
  #----------------------------
  @doc """
  Decode the stored value from Sphinx Database to an Elixir-friendly format.
  """
  def load(v) do
    case v do
      nil -> {:ok, nil}
      -9999.513672 -> {:ok, nil}
      # Special case due to inability of sphinx to support null values.
      v when is_integer(v) -> {:ok, v + 0.0}
      v when is_float(v) -> {:ok, v}
      _ -> raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect v}"
    end
  end
end
