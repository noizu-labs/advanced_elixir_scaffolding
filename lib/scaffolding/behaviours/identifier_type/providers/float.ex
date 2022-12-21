#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Float.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  
  def type(), do: :float
  
  def __valid_identifier__(identifier, c) do
    cond do
      !is_float(identifier) -> {:error, {:identifier, :expected_float}}
      :else ->
        case range = c[:constraint] do
          nil -> :ok
          {:infinity, :infinity} -> :ok
          {:infinity, re} when identifier <= re -> :ok
          {:infinity, re} when identifier > re -> {:error, {:identifier, {:not_in_range, range}, identifier}}
          {rs, :infinity} when identifier >= rs -> :ok
          {rs, :infinity} when identifier < rs -> {:error, {:identifier, {:not_in_range, range}, identifier}}
          {rs, re} when identifier >= rs and identifier <= re -> :ok
          {rs, _} when identifier < rs -> {:error, {:identifier, {:not_in_range, range}, identifier}}
          {_, re} when identifier > re -> {:error, {:identifier, {:not_in_range, range}, identifier}}
          v -> {:error, {:configuration , :unsupported, v}}
        end
    end
  end
  
  
  def __sref_section_regex__(_c), do: {:ok, "-?[0-9]+\.[0-9]+"}
  
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_float(identifier), do: {:ok, Float.to_string(identifier)}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    case Float.parse(identifier) do
      {v, ""} ->
        case __valid_identifier__(v, c) do
          :ok -> {:ok, v}
          v -> v
        end
      v -> {:error, {:serialized_identifier, {:parse_failed, v}, identifier}}
    end
  end
end
