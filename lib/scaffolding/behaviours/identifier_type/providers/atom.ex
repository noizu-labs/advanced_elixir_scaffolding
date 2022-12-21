#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Atom.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :atom
  
  def __valid_identifier__(identifier, c) do
    cond do
      !is_atom(identifier) -> {:error, {:identifier, :expected_atom}}
      constraint = c[:constraint] ->
        case constraint do
          :existing -> :ok
          :any -> :ok
          nil -> :ok
          v when is_list(v) ->
            Enum.member?(v, identifier) && :ok || {:error, {:identifier, :not_in_white_list, identifier}}
          v = %MapSet{} ->
            Enum.member?(v, identifier) && :ok || {:error, {:identifier, :not_in_white_list, identifier}}
          v when is_function(v, 0) -> v.()[identifier] && :ok || {:error, {:identifier, :not_in_white_list, identifier}}
          v when is_function(v, 1) -> v.(identifier) && :ok || {:error, {:identifier, :not_in_white_list, identifier}}
          {m, f} -> apply(m, f, [identifier]) && :ok || {:error, {:identifier, :not_in_white_list, identifier}}
          _ -> {:error, :invalid_constraint}
        end
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(c) do
    v = cond do
          is_list(c[:constraint]) -> Enum.join(c[:constraint], "|")
          :else -> "[a-zA-Z0-9_]*"
        end
    {:ok, v}
  end
  
  def __id_to_string__(nil, c) do
    cond do
      c[:nil?] -> {:ok, Atom.to_string(nil)}
      :else -> {:error, {:identifier, :is_nil, nil}}
    end
  end
  def __id_to_string__(identifier, c) when is_atom(identifier) do
    cond do
      c[:constraint] == :existing -> {:ok, Atom.to_string(identifier)}
      c[:constraint] == nil -> {:ok, Atom.to_string(identifier)}
      constraint = c[:constriant] ->
        case constraint do
          v when is_list(v) ->
            Enum.member?(v, identifier) && Atom.to_string(identifier) || {:error, {:identifier, :unsupported_atom, identifier}}
          v = %MapSet{} ->
            Enum.member?(v, identifier) && Atom.to_string(identifier) || {:error, {:identifier, :unsupported_atom, identifier}}
          v when is_function(v, 0) -> v.()[identifier] && Atom.to_string(identifier) || {:error, {:identifier, :unsupported_atom, identifier}}
          v when is_function(v, 1) -> v.(identifier) && Atom.to_string(identifier) || {:error, {:identifier, :unsupported_atom, identifier}}
          {m, f} -> apply(m, f, [identifier]) && Atom.to_string(identifier) || {:error, {:identifier, :unsupported_atom, identifier}}
          v -> {:error, {:identifier, :unsupported_constraint, v}}
        end
        |> case do
             e = {:error, _} -> e
             v -> {:ok, v}
           end
      :else -> {:ok, Atom.to_string(identifier)}
    end
  end
  def __id_to_string__(identifier, _c), do: {:error, {:identifier, :expected_atom, identifier}}
  
  
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    cond do
      constraint = c[:constraint] ->
        case constraint do
          :existing -> {:ok, String.to_existing_atom(identifier)}
          :any -> {:ok, String.to_atom(identifier)}
          nil -> {:ok, String.to_atom(identifier)}
          v when is_list(v) ->
            Enum.find(v, &("#{&1}" == identifier)) && {:ok, String.to_atom(identifier)} || {:error, {:serialized_identifier, :not_in_white_list, identifier}}
          v = %MapSet{} ->
            Enum.find(v, &("#{&1}" == identifier)) && {:ok, String.to_atom(identifier)} || {:error, {:serialized_identifier, :not_in_white_list, identifier}}
          v when is_function(v, 0) -> v.()[identifier] && {:ok, String.to_atom(identifier)} || {:error, {:serialized_identifier, :not_in_white_list, identifier}}
          v when is_function(v, 1) -> v.(identifier)  && {:ok, String.to_atom(identifier)} || {:error, {:serialized_identifier, :not_in_white_list, identifier}}
          {m, f} -> apply(m, f, [identifier]) && {:ok, String.to_atom(identifier)} || {:error, {:serialized_identifier, :not_in_white_list, identifier}}
          _ -> {:error, {:invalid_constraint, constraint}}
        end
      :else -> {:ok, String.to_existing_atom(identifier)}
    end
  end
end