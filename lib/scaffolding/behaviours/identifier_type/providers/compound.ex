#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Compound.IdentifierType do
  @moduledoc """
  The `Noizu.DomainObject.Compound.IdentifierType` module implements the `Noizu.DomainObject.IdentifierTypeBehaviour`
  behaviour for compound identifier types used in the Noizu.DomainObject framework.

  This module provides functions for validating, encoding, and decoding compound identifiers. Compound identifiers are tuples
  that contain multiple components, each representing a different part of the identifier.

  # Callbacks
  - `type/0`: Returns the type of the identifier (compound).
  - `__valid_identifier__/2`: Checks if a provided value is correct for the compound identifier type.
  - `__sref_section_regex__/1`: Prepares a regex snippet for matching the compound identifier.
  - `__id_to_string__/2`: Encodes a valid compound identifier into a string for sref encoding.
  - `__string_to_id__/2`: Decodes a string into the compound identifier type.
  """


  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :compound

  @doc """
  Checks if the provided value is correct for the compound identifier type.

  ## Params
  - identifier: The identifier value to check.
  - configuration: Additional configuration for the identifier.

  ## Returns
  - :ok: If the identifier value is correct.
  - {:error, reason}: If the identifier value is incorrect, with the reason for the failure.
  """
  def __valid_identifier__(identifier, _c) do
    cond do
      Kernel.match?({:ref, _, _}, identifier) -> {:error, {:identifier, :expected_compound}}
      Kernel.match?({:ext_ref, _, _}, identifier) -> {:error, {:identifier, :expected_compound}}
      !is_tuple(identifier) -> {:error, {:identifier, :expected_compound}}
      :else -> :ok
    end
  end


  @doc """
  Prepares a regex snippet for matching the compound identifier.

  ## Params
  - configuration: Additional configuration for the identifier.

  ## Returns
  - {:ok, regex}: If the regex snippet is prepared successfully.
  - {:error, reason}: If there is an error preparing the regex snippet, with the reason for the failure.
  """
  def __sref_section_regex__(c) do
    cond do
      template = (is_tuple(c[:template]) && c[:template]) ->
        inner = template
                |> Tuple.to_list()
                |> Enum.map(
                     fn(t) ->
                       {:ok, v} = Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(t)
                       "(" <> v <> ")"
                     end)
        {:ok, "\\{" <> Enum.join(inner, ",") <> "\\}"}
      :else ->
        {:error, {:configuration, :template_required_for_sref_regex, c}}
    end
  end


  @doc """
  Encodes a valid compound identifier into a string for sref encoding.

  ## Params
  - identifier: The valid identifier value to encode.
  - configuration: Additional configuration for the identifier.

  ## Returns
  - {:ok, encoded_string}: If the identifier is encoded successfully.
  - {:error, reason}: If there is an error encoding the identifier, with the reason for the failure.
  """
  def __id_to_string__(nil, _c), do: nil
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
         true <- is_tuple(c[:template]) || {:error, {:template, :malformed_not_tuple, c[:template]}},
         true <- is_tuple(identifier) || {:error, {:identifier, :malformed_not_tuple, identifier}},
         template_list = Tuple.to_list(c[:template]),
         id_list = Tuple.to_list(identifier),
         true <- length(template_list) == length(id_list) || {:error, {:identifier, :template_mismatch, identifier}} do
      l = for index <- 0..(length(template_list) - 1) do
            {:ok, v} = Noizu.DomainObject.IdentifierTypeResolver.__id_to_string__(Enum.at(id_list, index), Enum.at(template_list, index))
            v
          end
      {:ok, "{" <> Enum.join(l, ",") <> "}"}
    else
      e = {:error, _} -> e
      e -> {:error, {:to_string_failed, e, identifier}}
    end
  end

  @doc """
  Decodes a string into the compound identifier type.

  ## Params
  - string: The string to decode into the compound identifier type.
  - configuration: Additional configuration for the identifier.

  ## Returns
  - {:ok, identifier}: If the string is decoded successfully into the compound identifier type.
  - {:error, reason}: If there is an error decoding the string, with the reason for the failure.
  """
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    template = c[:template]
    cond do
      is_tuple(template) ->
        template_list = Tuple.to_list(template)
        {:ok, extract} = __sref_section_regex__(c)
        {:ok, extract} = Regex.compile("^#{extract}$")
        case Regex.run(extract, identifier, capture: :first) do
          [] -> {:error, {:serialized_identifier, {:regex_mismatch, extract.source}, identifier}}
          [v] ->
            v = String.slice(v, 1..-2)
            {components, _} = Enum.map_reduce(template_list, {template_list, v},
              fn(_, {tl,ms}) ->
                rx = Enum.map(tl, fn(t) ->
                  {:ok, rxc} = Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(t)
                  "(#{rxc})"
                end) |> Enum.join(",")
                {:ok, rxc} = Regex.compile("^#{rx}$")
                [h|utl] = tl
                case Regex.run(rxc, ms, capture: :all_but_first) do
                  [m|_] ->
                    {:ok,r} = Noizu.DomainObject.IdentifierTypeResolver.__string_to_id__(m, h)
                    {r, {utl, String.replace_prefix(ms, m, "") |> String.replace_prefix(",", "")}}
                end
            end)
            raw = List.to_tuple(components)
            case c[:serializer] do
              prep when is_function(prep, 2) ->
                case prep.(:decode, raw) do
                  {:ok, v} -> {:ok, v}
                  {:error, v} -> {:error, v}
                  v -> {:ok, v}
                end
              {m, f} ->
                case apply(m, f, [:decode, raw]) do
                  {:ok, v} -> {:ok, v}
                  {:error, v} -> {:error, v}
                  v -> {:ok, v}
                end
              nil -> {:ok, raw}
              v -> {:error, {:config, :unsupported_serializer, v}}
            end
          _ -> {:error, {:serialized_identifier, {:regex_mismatch, extract.source}, identifier}}
        end
    end
  end
end
