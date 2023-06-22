#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Sphinx.Type.Bool do
  @moduledoc """
  Encode/Decode Bool value for Sphinx Database.
  This module provides an Ecto.Type implementation for handling boolean values in the context of the Sphinx search engine. It is responsible for casting, loading, and dumping boolean values while adhering to the format understood by Sphinx.
  """
  use Ecto.Type
  require Noizu.DomainObject
  Noizu.DomainObject.noizu_sphinx_handler()


  #===------
  #
  #===------
  @boolean_true MapSet.new(["TRUE", "True", "true", "T", "t", "on", "On", "ON", "Y", "y", "YES", "yes", "Yes", true, 1])
  @boolean_false MapSet.new(["FALSE", "False", "false", "F", "f", "off", "Off", "OFF", "NO", "N", "n", "no", "No", false, 0])

  @doc """
  Constructs search clauses based on field values.
  This function is responsible for generating search clauses for the given field and parameters. It takes into account the field's structure and ensures that the generated clauses are compatible with the Sphinx search engine.
  """
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
  Casts the given value to a boolean.
  This function takes an input value and attempts to convert it into a boolean value. It supports various string representations as well as numeric representations for true and false.
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
  This function works similarly to `cast/1`, but it raises an `Ecto.CastError` exception if the given value cannot be converted into a boolean value.
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

  def dump(v) do
    case v do
      0 -> {:ok, false}
      v -> {:ok, v && true || false}
    end
  end

  #----------------------------
  # load
  #----------------------------
  @doc """
  Loads the given value as a boolean.
  This function takes an input value and converts it into a boolean value if possible. It supports various string representations as well as numeric representations for true and false.
  """
  def load(v) do
    case v do
      0 -> {:ok, false}
      "false" -> {:ok, false}
      v -> {:ok, v && true || false}
    end
  end
end
