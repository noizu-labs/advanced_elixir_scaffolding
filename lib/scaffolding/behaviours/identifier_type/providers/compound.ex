#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Compound.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :compound
  
  def __valid_identifier__(identifier, _c) do
    cond do
      Kernel.match?({:ref, _, _}, identifier) -> {:error, {:identifier, :expected_compound}}
      Kernel.match?({:ext_ref, _, _}, identifier) -> {:error, {:identifier, :expected_compound}}
      !is_tuple(identifier) -> {:error, {:identifier, :expected_compound}}
      :else -> :ok
    end
  end
  
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
