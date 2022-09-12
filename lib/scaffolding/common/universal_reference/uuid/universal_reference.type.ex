#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UUID.UniversalReference.Type do
  @moduledoc """
  Ecto ENUM Custom Type.
  """
  use Ecto.Type

  #----------------------------
  # type
  #----------------------------
  @doc false
  def type, do: :uuid

  #----------------------------
  # cast
  #----------------------------
  @doc """
  Casts to Ref.
  """
  def cast(v) do
    cond do
      v == nil -> {:ok, nil}
      v == 0 -> {:ok, nil}
      u = Noizu.DomainObject.UUID.UniversalReference.encode(v) -> {:ok, u}
      :else -> :error
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
  def dump(v) when is_integer(v) do
    {:ok, v}
  end
  def dump(v) do
    case Noizu.EctoEntity.Protocol.universal_identifier(v) do
      nil -> {:ok, nil}
      <<v::binary-size(16)>> -> {:ok, v}
      v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> -> {:ok, UUID.string_to_binary!(v)}
    end
  end

  #----------------------------
  # load
  #----------------------------
  def load(v) do
    cond do
      v == nil -> {:ok, nil}
      v == 0 -> {:ok, nil}
      u = Noizu.DomainObject.UUID.UniversalReference.encode(v) -> {:ok, u}
      :else -> raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect v}"
    end
  end
end
