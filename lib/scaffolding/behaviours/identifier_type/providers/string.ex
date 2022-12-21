#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.String.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :string
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_bitstring(identifier) -> {:error, {:identifier, :expected_string, identifier}}
      :else -> :ok
    end
  end
  
  
  def __sref_section_regex__(_c), do: {:ok, "\"[0-9a-zA-Z_\\-\\.]*\""}
  
  
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_bitstring(identifier), do: {:ok, "\"#{identifier}\""}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, _c) do
    cond do
      String.starts_with?(identifier, "\"") && String.ends_with?(identifier, "\"") -> {:ok, String.slice(identifier, 1..-2)}
      :else -> {:error, :invalid_serialized_string}
    end
  end
end
