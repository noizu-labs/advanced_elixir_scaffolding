#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UUID.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour

  def __noizu_info__(:type), do: :identifier_type

  @impl true
  def type(), do: :uuid

  @doc """
  Checks if the provided value is a valid UUID.

  ## Params
  - identifier: The UUID identifier value to check.
  - _c: Additional configuration for the identifier (not used).

  ## Returns
  - :ok: If the identifier value is a valid UUID.
  - {:error, reason}: If the identifier value is not a valid UUID, with the reason for the failure.
  """
  @impl true
  def __valid_identifier__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, _} -> :ok
      {:error, d} -> {:error, {:identifier, {:invalid_uuid, d}, identifier}}
    end
  end

  @doc """
  Prepares a regex snippet for matching UUIDs.

  ## Params
  - _c: Additional configuration for the identifier (not used).

  ## Returns
  - {:ok, regex}: If the regex snippet is prepared successfully.
  - {:error, reason}: If there is an error preparing the regex snippet, with the reason for the failure.
  """
  @impl true
  def __sref_section_regex__(_c), do: {:ok, "[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"}

  @doc """
  Encodes a UUID identifier into a string.

  ## Params
  - identifier: The UUID identifier value to encode.
  - _c: Additional configuration for the identifier (not used).

  ## Returns
  - {:ok, encoded_string}: If the identifier is encoded successfully.
  - {:error, reason}: If there is an error encoding the identifier, with the reason for the failure.
  """
  @impl true
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, b} -> b[:type] == :default && {:ok, b[:uuid]} || {:ok, UUID.binary_to_string!(b[:binary])}
      {:error, d} -> {:error, {:identifier, {:invalid_uuid, d}, identifier}}
    end
  end

  @doc """
  Decodes a string into a UUID identifier.

  ## Params
  - identifier: The string to decode into the UUID identifier.
  - _c: Additional configuration for the identifier (not used).

  ## Returns
  - {:ok, identifier}: If the string is decoded successfully into the UUID identifier.
  - {:error, reason}: If there is an error decoding the string, with the reason for the failure.
  """
  @impl true
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
