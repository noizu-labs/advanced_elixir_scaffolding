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


  #===------
  #
  #===------
  @boolean_true MapSet.new(["TRUE", "True", "true", "T", "t", "on", "On", "ON", "Y", "y", "YES", "yes", "Yes", true, 1])
  @boolean_false MapSet.new(["FALSE", "False", "false", "F", "f", "off", "Off", "OFF", "NO", "N", "n", "no", "No", false, 0])

  def __search_clauses__(_index, {field, _settings}, conn, params, _context, options) do
    search = case field do
               {p, f} -> "#{p}.#{f}"
               _ -> "#{field}"
             end
    case Noizu.AdvancedScaffolding.Helpers.extract_setting(:extract, search, conn, params, nil, options) do
      {_, nil} -> nil
      {_, v} ->
        cond do
          Enum.member?(@boolean_true, v) ->
            param = String.replace(search, ".", "_")
            "#{param} == 1"
          Enum.member?(@boolean_false, v) ->
            param = String.replace(search, ".", "_")
            "#{param} == 0"
          :else -> nil
        end
      _ -> nil
    end
  end

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
