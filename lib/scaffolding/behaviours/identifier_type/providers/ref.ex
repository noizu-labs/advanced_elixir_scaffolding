#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Ref.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :ref
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !(Kernel.match?({:ref, _, _}, identifier) || Kernel.match?({:ext_ref, _, _}, identifier))   -> {:error, {:identifier, :expected_ref_tup}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(_c) do
    rp = "ref\\.[a-zA-Z0-9\\-_]*"
    ri = "[a-zA-Z_\\-0-9@,\.\[\]\{\}]*"
    {:ok, "\(#{rp}\.#{ri}\)|\(#{rp}\{#{ri}\}\)|\(#{rp}\[#{ri}\]\)"}
  end
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
