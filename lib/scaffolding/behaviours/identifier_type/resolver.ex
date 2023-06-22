#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.IdentifierTypeResolver do
  @moduledoc """
  The `Noizu.DomainObject.IdentifierTypeResolver` module provides plumbing and default logic for built-in type handlers
  in the Noizu.DomainObject framework.

  This module acts as a resolver for identifier type handlers, allowing dynamic resolution of the appropriate handler
  for a given identifier type.

  # Functions
  - `__valid_identifier__/2`: Calls the appropriate handler's `__valid_identifier__/2` function.
  - `__sref_section_regex__/1`: Calls the appropriate handler's `__sref_section_regex__/1` function.
  - `__id_to_string__/2`: Calls the appropriate handler's `__id_to_string__/2` function.
  - `__string_to_id__/2`: Calls the appropriate handler's `__string_to_id__/2` function.
  - `__built_in_identifier_type__/0`: Returns a map of built-in identifier types and their corresponding handlers.
  - `__registered_identifier_types__/0`: Returns the map of registered identifier types and their handlers.
  - `provider_configuration/1`: Retrieves the configuration for a given identifier type.
  - `resolver/3`: Resolves and executes the appropriate handler function for the given action, identifier type, and arguments.
  """

  @doc """
  Calls the appropriate handler's `__valid_identifier__/2` function.

  ## Params
  - identifier: The identifier value.
  - t: The identifier type.

  ## Returns
  - The result of the `__valid_identifier__/2` function of the appropriate handler.
  """
  def __valid_identifier__(identifier, t), do: resolver(t, :__valid_identifier__, [identifier])


  @doc """
  Calls the appropriate handler's `__sref_section_regex__/1` function.

  ## Params
  - t: The identifier type.

  ## Returns
  - The result of the `__sref_section_regex__/1` function of the appropriate handler.
  """
  def __sref_section_regex__(t), do: resolver(t, :__sref_section_regex__, [])


  @doc """
  Calls the appropriate handler's `__id_to_string__/2` function.

  ## Params
  - identifier: The identifier value.
  - t: The identifier type.

  ## Returns
  - The result of the `__id_to_string__/2` function of the appropriate handler.
  """
  def __id_to_string__(identifier, t), do: resolver(t, :__id_to_string__, [identifier])

  @doc """
  Calls the appropriate handler's `__string_to_id__/2` function.

  ## Params
  - serialized_identifier: The serialized identifier value.
  - t: The identifier type.

  ## Returns
  - The result of the `__string_to_id__/2` function of the appropriate handler.
  """
  def __string_to_id__(serialized_identifier, t), do: resolver(t, :__string_to_id__, [serialized_identifier])


  @doc """
  Returns a map of built-in identifier types and their corresponding handlers.

  ## Returns
  - A map of built-in identifier types and their corresponding handler modules.
  """
  def __built_in_identifier_type__() do
    %{
      integer: Noizu.DomainObject.Integer.IdentifierType,
      float: Noizu.DomainObject.Float.IdentifierType,
      string: Noizu.DomainObject.String.IdentifierType,
      hash: Noizu.DomainObject.Hash.IdentifierType,
      uuid: Noizu.DomainObject.UUID.IdentifierType,
      atom: Noizu.DomainObject.Atom.IdentifierType,
      ref: Noizu.DomainObject.Ref.IdentifierType,
      compound: Noizu.DomainObject.Compound.IdentifierType,
      list: Noizu.DomainObject.List.IdentifierType,
    }
  end


  @doc """
  Returns the map of registered identifier types and their handlers.

  ## Returns
  - The map of registered identifier types and their corresponding handler modules.
  """
  @doc """
  @todo Should be prepared at runtime/compile time.
  """
  def __registered_identifier_types__() do
    __built_in_identifier_type__()
  end


  @doc """
  Retrieves the configuration for a given identifier type.

  ## Params
  - t: The identifier type.

  ## Returns
  - {p, c}: The handler module and its configuration.
  """
  def provider_configuration(t) do
    case t do
      {p,c} -> {__registered_identifier_types__()[p] || p, c}
      p when is_atom(p) -> {__registered_identifier_types__()[p] || p, []}
    end
  end

  @doc """
  Resolves and executes the appropriate handler function for the given action, identifier type, and arguments.

  ## Params
  - t: The identifier type.
  - action: The action to execute.
  - args: Additional arguments to pass to the handler function.

  ## Returns
  - The result of the resolved handler function.
  """
  defp resolver(t, action, args) do
    {p, c} = provider_configuration(t)
    apply(p, action, args ++ [c])
  rescue e -> {:error, {:rescue, e}}
  catch
    :exit, e -> {:error, {:exit, e}}
    e -> {:error, {:catch, e}}
  end
end
