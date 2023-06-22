#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Atom.IdentifierType do
  @moduledoc """
  The `Noizu.DomainObject.Atom.IdentifierType` module implements the `Noizu.DomainObject.IdentifierTypeBehaviour`
  behaviour for handling atom-based identifier types in the Noizu.DomainObject framework.

  This module provides functions for validating, encoding, and decoding atom-based identifiers. It also includes
  functionality for preparing regex snippets for matching identifiers.

  # Callbacks
  - `type/0`: Returns the type of the identifier.
  - `__valid_identifier__/2`: Checks if a provided value is correct for the identifier type.
  - `__sref_section_regex__/1`: Prepares a regex snippet for matching the identifier.
  - `__id_to_string__/2`: Encodes a valid identifier into a string for sref encoding.
  - `__string_to_id__/2`: Decodes a string into the identifier type.
  """

  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour

  def __noizu_info__(:type), do: :identifier_type


  #------------------------------------------
  # __noizu_info__/0
  #------------------------------------------
  @doc """
  Returns the type of the identifier.

  ## Returns
  - :identifier_type: The type of the identifier.
  """
  @impl true
  @spec type() :: atom
  def type(), do: :atom

  #------------------------------------------
  # __valid_identifier__
  #------------------------------------------
  @doc """
  Checks if the provided value is correct for the identifier type.

  ## Params
  - identifier: The identifier value to check.
  - c: The identifier configuration.

  ## Returns
  - :ok: If the identifier value is correct.
  - {:error, reason}: If the identifier value is incorrect, with the reason for the failure.
  """
  @impl true
  @spec __valid_identifier__(any(), any()) :: :ok | {:error, any()}
  def __valid_identifier__(identifier, c)
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

  #------------------------------------------
  # __sref_section_regex__
  #------------------------------------------
  @doc """
  Prepares a regex snippet for matching the identifier.

  ## Params
  - c: The identifier configuration.

  ## Returns
  - {:ok, regex}: If the regex snippet is prepared successfully.
  - {:error, reason}: If there is an error preparing the regex snippet, with the reason for the failure.
  """
  @impl true
  @spec __sref_section_regex__(any()) :: {:ok, String.t} | {:error, any()}
  def __sref_section_regex__(c) do
    v = cond do
          is_list(c[:constraint]) -> Enum.join(c[:constraint], "|")
          :else -> "[a-zA-Z0-9_]*"
        end
    {:ok, v}
  end


  #------------------------------------------
  # __id_to_string__
  #------------------------------------------
  @doc """
  Encodes a valid identifier into a string for sref encoding.

  ## Params
  - identifier: The valid identifier value to encode.
  - c: The identifier configuration.

  ## Returns
  - {:ok, encoded_string}: If the identifier is encoded successfully.
  - {:error, reason}: If there is an error encoding the identifier, with the reason for the failure.
  """
  @impl true
  @spec __id_to_string__(nil | atom, any()) :: {:ok, String.t} | {:error, any()}
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


  #------------------------------------------
  # __string_to_id__
  #------------------------------------------
  @doc """
  Decodes a string into the identifier type.

  ## Params
  - identifier: The string to decode into the identifier type.
  - c: The identifier configuration.

  ## Returns
  - {:ok, identifier}: If the string is decoded successfully into the identifier type.
  - {:error, reason}: If there is an error decoding the string, with the reason for the failure.
  """
  @impl true
  @spec __string_to_id__(String.t, any()) :: {:ok, any()} | {:error, any()}
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
