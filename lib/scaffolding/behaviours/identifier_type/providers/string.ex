#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.String.IdentifierType do
  @moduledoc """
  The `Noizu.DomainObject.String.IdentifierType` module implements the `Noizu.DomainObject.IdentifierTypeBehaviour`
  behaviour for string identifier types used in the Noizu.DomainObject framework.

  This module provides functions for validating, encoding, and decoding string identifier values.

  # Callbacks
  - `type/0`: Returns the type of the identifier.
  - `__valid_identifier__/2`: Checks if a provided value is correct for the identifier type.
  - `__sref_section_regex__/1`: Prepares a regex snippet for matching the identifier.
  - `__id_to_string__/2`: Encodes a valid identifier into a string for sref encoding.
  - `__string_to_id__/2`: Decodes a string into the identifier type.
  """

  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type

  @doc """
  Returns the type of the identifier as :string.
  """
  def type(), do: :string


  @doc """
  Checks if the provided value is correct for the identifier type.

  ## Params
  - identifier: The identifier value to check.
  - _c: Additional configuration for the identifier (unused).

  ## Returns
  - :ok: If the identifier value is correct.
  - {:error, reason}: If the identifier value is incorrect, with the reason for the failure.
  """
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_bitstring(identifier) -> {:error, {:identifier, :expected_string, identifier}}
      :else -> :ok
    end
  end


  @doc """
  Prepares a regex snippet for matching the identifier.

  ## Params
  - _c: Additional configuration for the identifier (unused).

  ## Returns
  - {:ok, regex}: If the regex snippet is prepared successfully.
  - {:error, reason}: If there is an error preparing the regex snippet, with the reason for the failure.
  """
  def __sref_section_regex__(_c), do: {:ok, "\"[0-9a-zA-Z_\\-\\.]*\""}

  @doc """
  Encodes a valid identifier into a string for sref encoding.

  ## Params
  - identifier: The valid identifier value to encode.
  - _c: Additional configuration for the identifier (unused).

  ## Returns
  - {:ok, encoded_string}: If the identifier is encoded successfully.
  - {:error, reason}: If there is an error encoding the identifier, with the reason for the failure.
  """
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_bitstring(identifier), do: {:ok, "\"#{identifier}\""}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}

  @doc """
  Decodes a string into the identifier type.

  ## Params
  - identifier: The string to decode into the identifier type.
  - _c: Additional configuration for the identifier (unused).

  ## Returns
  - {:ok, identifier}: If the string is decoded successfully into the identifier type.
  - {:error, reason}: If there is an error decoding the string, with the reason for the failure.
  """
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, _c) do
    cond do
      String.starts_with?(identifier, "\"") && String.ends_with?(identifier, "\"") -> {:ok, String.slice(identifier, 1..-2)}
      :else -> {:error, :invalid_serialized_string}
    end
  end
end
