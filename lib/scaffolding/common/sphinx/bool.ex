#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Sphinx.Type.Bool do
  @moduledoc """
  Encode/Decode Bool value for Sphinx Database.
  """
  use Ecto.Type
  require Noizu.DomainObject
  Noizu.DomainObject.noizu_sphinx_handler()

  #----------------------------
  # type
  #----------------------------
  @doc false
  def type, do: :bool

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
