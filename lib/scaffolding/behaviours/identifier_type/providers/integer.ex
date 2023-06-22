#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Integer.IdentifierType do
  @moduledoc """
  The `Noizu.DomainObject.Integer.IdentifierType` module implements the `Noizu.DomainObject.IdentifierTypeBehaviour`
  behaviour for integer identifier types used in the Noizu.DomainObject framework.

  # Callbacks
  - `type/0`: Returns the type of the identifier.
  - `__valid_identifier__/2`: Checks if a provided value is correct for the identifier type.
  - `__sref_section_regex__/1`: Prepares a regex snippet for matching the identifier.
  - `__id_to_string__/2`: Encodes a valid identifier into a string for sref encoding.
  - `__string_to_id__/2`: Decodes a string into the identifier type.
  """


  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  
  def type(), do: :integer


  @doc """
  Checks if the provided value is correct for the identifier type.

  ## Params
  - identifier: The identifier value to check.
  - configuration: Additional configuration for the identifier.

  ## Returns
  - :ok: If the identifier value is correct.
  - {:error, reason}: If the identifier value is incorrect, with the reason for the failure.
  """
  def __valid_identifier__(identifier, c) do
    cond do
      !is_integer(identifier) -> {:error, {:identifier, :expected_integer}}
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


  @doc """
  Prepares a regex snippet for matching the identifier.

  ## Params
  - configuration: Additional configuration for the identifier.

  ## Returns
  - {:ok, regex}: If the regex snippet is prepared successfully.
  - {:error, reason}: If there is an error preparing the regex snippet, with the reason for the failure.
  """
  def __sref_section_regex__(_c), do: {:ok, "-?[0-9]+"}


  @doc """
  Encodes a valid identifier into a string for sref encoding.

  ## Params
  - identifier: The valid identifier value to encode.
  - configuration: Additional configuration for the identifier.

  ## Returns
  - {:ok, encoded_string}: If the identifier is encoded successfully.
  - {:error, reason}: If there is an error encoding the identifier, with the reason for the failure.
  """
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_integer(identifier), do: {:ok, Integer.to_string(identifier)}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}


  @doc """
  Decodes a string into the identifier type.

  ## Params
  - string: The string to decode into the identifier type.
  - configuration: Additional configuration for the identifier.

  ## Returns
  - {:ok, identifier}: If the string is decoded successfully into the identifier type.
  - {:error, reason}: If there is an error decoding the string, with the reason for the failure.
  """
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    case Integer.parse(identifier) do
      {v, ""} ->
        case __valid_identifier__(v, c) do
          :ok -> {:ok, v}
          v -> v
        end
      v -> {:error, {:serialized_identifier, {:parse_failed, v}, identifier}}
    end
  end
end
