#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UUID.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :uuid
  
  def __valid_identifier__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, _} -> :ok
      {:error, d} -> {:error, {:identifier, {:invalid_uuid, d}, identifier}}
    end
  end
  
  def __sref_section_regex__(_c), do: {:ok, "[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"}
  
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, b} -> b[:type] == :default && {:ok, b[:uuid]} || {:ok, UUID.binary_to_string!(b[:binary])}
      {:error, d} -> {:error, {:identifier, {:invalid_uuid, d}, identifier}}
    end
  end
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_uuid, identifier}}
  def __string_to_id__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, d} ->
        cond do
          d[:binary] -> {:ok, d[:binary]}
          d[:type] == :default -> {:ok, UUID.string_to_binary!(d[:uuid])}
        end
      e -> {:error, {:serialized_identifier, {:invalid_uuid, e}, identifier}}
    end
  end
end

