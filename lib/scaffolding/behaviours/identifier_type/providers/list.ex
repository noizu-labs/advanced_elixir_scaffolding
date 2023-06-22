#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.List.IdentifierType do
  @moduledoc """
  The `Noizu.DomainObject.List.IdentifierType` module implements the `Noizu.DomainObject.IdentifierTypeBehaviour`,
  providing identifier type handling functionality for list identifiers.

  # Behaviour
  This module adheres to the `Noizu.DomainObject.IdentifierTypeBehaviour` behaviour.
  """

  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type


  @doc """
  Returns the type of the identifier.

  ## Returns
  - :list: The type of the identifier.
  """
  @impl true
  def type(), do: :list


  @doc """
  Checks if the provided value is a valid identifier for the list identifier type.

  ## Params
  - identifier: The identifier value to check.
  - c: Additional configuration for the identifier.

  ## Returns
  - :ok: If the identifier value is valid.
  - {:error, {:identifier, :not_list}}: If the identifier value is not a list.
  """
  @impl true
  def __valid_identifier__(identifier, c)
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_list(identifier) -> {:error, {:identifier, :not_list}}
      :else -> :ok
    end
  end
  
  defp __sref_inner__(c) do
    cond do
      template = is_list(c[:template]) && c[:template] ->
        Enum.map(template, fn(t) ->
          {:ok, t} = Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(t)
          t
        end) |> Enum.join("|")
      template =  (is_tuple(c[:template]) or is_atom(c[:template])) && c[:template] ->
        {:ok, inner} = Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(template)
        inner
      :else ->
        "[a-zA-Z0-9\.\-_@\+]+"
    end
  end


  @doc """
  Prepares a regex pattern for matching the identifier section in sref.

  ## Params
  - c: Additional configuration for the identifier.

  ## Returns
  - {:ok, regex}: If the regex pattern is prepared successfully.
  - {:error, reason}: If there is an error preparing the regex pattern.
  """
  @impl true
  def __sref_section_regex__(c) do
    element = __sref_inner__(c)
    {:ok, "\\[((" <> element <> "),?)+\\]"}
  end


  @doc """
  Encodes a valid identifier into a string for sref encoding.

  ## Params
  - nil: The identifier value, which should not be nil.
  - c: Additional configuration for the identifier.

  ## Returns
  - {:error, {:identifier, :is_nil, nil}}: If the identifier value is nil.
  - {:ok, encoded_string}: If the identifier is encoded successfully.
  - {:error, reason}: If there is an error encoding the identifier.
  """
  @impl true
  def __id_to_string__(nil, _c), do: {:error, {:identifier, :is_nil, nil}}
  def __id_to_string__(identifier, c) do
    p = case c[:serializer] do
          prep when is_function(prep, 2) ->
            case prep.(:encode, identifier) do
              {:ok, v} -> {:ok, v}
              {:error, v} -> {:error, v}
              v -> {:ok, v}
            end
          {m, f} ->
            case apply(m, f, [:encode, identifier]) do
              {:ok, v} -> {:ok, v}
              {:error, v} -> {:error, v}
              v -> {:ok, v}
            end
          nil -> {:ok, identifier}
          v -> {:error, {:config, :unsupported_serializer, v}}
        end
    with {:ok, identifier} <- p,
         template <- c[:template],
         true <- is_tuple(c[:template]) || is_atom(c[:template]) || {:error, {:template, :malformed, c[:template]}},
         true <- is_list(identifier) || {:error, {:identifier, :malformed_not_list, identifier}} do
      l = Enum.map(identifier, fn(id) ->
        {:ok, v} = Noizu.DomainObject.IdentifierTypeResolver.__id_to_string__(id, template)
        v
      end)
      {:ok, "[" <> Enum.join(l, ",") <> "]"}
    else
      e = {:error, _} -> e
      e -> {:error, {:to_string_failed, e, identifier}}
    end
  end


  @doc """
  Decodes a string into the identifier type.

  ## Params
  - identifier: The string to decode into the identifier type.
  - _c: Additional configuration for the identifier.

  ## Returns
  - {:error, {:serialized_identifier, :not_string, identifier}}: If the identifier is not a string.
  - {:error, {:invalid_serialized_identifier, error, identifier}}: If the identifier is invalid.
  """
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    with {:ok, raw} <- __sref_section_regex__(c),
         {:ok, r} <- Regex.compile("^#{raw}$"),
         true <- Regex.match?(r, identifier) do
      # identifier = String.slice(identifier, 1..-2)
      {:error, :nyi}
    else
      error -> {:error, {:invalid_serialized_identifier, error, identifier}}
    end
  end

end
