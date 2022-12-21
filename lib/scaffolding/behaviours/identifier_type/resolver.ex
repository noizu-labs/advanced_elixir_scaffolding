#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.IdentifierTypeResolver do
  @moduledoc """
  Provides plumbing/default logic for built in type handlers.
  """
  def __valid_identifier__(identifier, t), do: resolver(t, :__valid_identifier__, [identifier])
  def __sref_section_regex__(t), do: resolver(t, :__sref_section_regex__, [])
  def __id_to_string__(identifier, t), do: resolver(t, :__id_to_string__, [identifier])
  def __string_to_id__(serialized_identifier, t), do: resolver(t, :__string_to_id__, [serialized_identifier])
  
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
  Should be prepared at runtime/compile time.
  """
  def __registered_identifier_types__() do
    __built_in_identifier_type__()
  end
  
  
  def provider_configuration(t) do
    case t do
      {p,c} -> {__registered_identifier_types__()[p] || p, c}
      p when is_atom(p) -> {__registered_identifier_types__()[p] || p, []}
    end
  end
  
  defp resolver(t, action, args) do
    {p, c} = provider_configuration(t)
    apply(p, action, args ++ [c])
  rescue e -> {:error, {:rescue, e}}
  catch
    :exit, e -> {:error, {:exit, e}}
    e -> {:error, {:catch, e}}
  end
end


