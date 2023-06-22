#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Ref.IdentifierType do
  @moduledoc """
  The `Noizu.DomainObject.Ref.IdentifierType` module implements the `Noizu.DomainObject.IdentifierTypeBehaviour` behaviour,
  providing identifier type handling functionality for reference identifiers.

  This module is responsible for encoding, decoding, and validating reference identifiers used in the Noizu.DomainObject framework.

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
  Returns the type of the identifier.
  """
  @impl true
  def type(), do: :ref


  @doc """
  Checks if the provided value is correct for the identifier type.

  ## Params
  - identifier: The identifier value to check.
  - _c: Additional configuration for the identifier (unused).

  ## Returns
  - :ok: If the identifier value is correct.
  - {:error, reason}: If the identifier value is incorrect, with the reason for the failure.
  """
  @impl true
  def __valid_identifier__(identifier, _c) do
    cond do
      !(Kernel.match?({:ref, _, _}, identifier) || Kernel.match?({:ext_ref, _, _}, identifier))   -> {:error, {:identifier, :expected_ref_tup}}
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
  @impl true
  def __sref_section_regex__(_c) do
    rp = "ref\\.[a-zA-Z0-9\\-_]*"
    ri = "[a-zA-Z_\\-0-9@,\.\[\]\{\}]*"
    {:ok, "\(#{rp}\.#{ri}\)|\(#{rp}\{#{ri}\}\)|\(#{rp}\[#{ri}\]\)"}
  end


  @doc """
  Encodes a valid identifier into a string for sref encoding.

  ## Params
  - nil: The identifier value (unused).
  - _c: Additional configuration for the identifier (unused).

  ## Returns
  - {:error, reason}: If the identifier is nil.
  - {:ok, encoded_string}: If the identifier is encoded successfully.
  """
  @impl true
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, c) do
    with {:ok, {_, m, _} = _ref} <- Noizu.ERP.ref_ok(identifier),
         {:ok, sref} <- Noizu.ERP.sref_ok(identifier) do
      case c[:constraint] do
        nil -> sref
        v when is_list(v) ->
          Enum.member?(v, m) && sref || {:error, {:identifier, :not_in_white_list, identifier}}
        v = %MapSet{} ->
          Enum.member?(v, m) && sref || {:error, {:identifier, :not_in_white_list, identifier}}
        v when is_function(v, 0) ->
          v.()[m] && sref || {:error, {:identifier, :not_in_white_list, identifier}}
        v when is_function(v, 1) ->
          v.(m) && sref || {:error, {:identifier, :not_in_white_list, identifier}}
        {m, f} ->
          apply(m, f, [m]) && sref || {:error, {:identifier, :not_in_white_list, identifier}}
        v ->
          {:error, {:constraint, :unsupported, v}}
      end |> case do
               e = {:error, _} -> e
               v -> {:ok, "(#{v})"}
             end
    else
      e -> {:error, {:invalid_ref, e, identifier}}
    end
  end

  @doc """
  Decodes a string into the identifier type.

  ## Params
  - identifier: The string to decode into the identifier type.
  - c: Additional configuration for the identifier.

  ## Returns
  - {:error, reason}: If the identifier is not in the whitelist or has an unsupported constraint.
  - {:ok, identifier}: If the string is decoded successfully into the identifier type.
  """
  @impl true
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    identifier = cond do
                   String.starts_with?(identifier, "(") && String.ends_with?(identifier, ")") -> String.slice(identifier, 1..-2)
                   :else -> identifier
                 end
    cond do
      constraint = c[:constraint] ->
        with {:ok, {_, m, _} = ref} <- Noizu.ERP.ref_ok(identifier) do
          case constraint do
            v when is_list(v) -> Enum.member?(v, m) && {:ok, ref} || {:error, {:serialized_identifier, :not_in_whitelist, identifier}}
            v = %MapSet{} -> Enum.member?(v, m) && {:ok, ref} || {:error, {:serialized_identifier, :not_in_whitelist, identifier}}
            v when is_function(v, 0) -> v.()[m] && {:ok, ref} || {:error, {:serialized_identifier, :not_in_whitelist, identifier}}
            v when is_function(v, 1) -> v.(m) && {:ok, ref} || {:error, {:serialized_identifier, :not_in_whitelist, identifier}}
            {m, f} -> apply(m, f, [m]) && {:ok, ref} || {:error, {:serialized_identifier, :not_in_whitelist, identifier}}
            _ -> {:error, {:configuration, :unsupported_contraint_type, c}}
          end
        else
          e -> e
        end
      :else ->
        Noizu.ERP.ref_ok(identifier)
    end
  end
end
