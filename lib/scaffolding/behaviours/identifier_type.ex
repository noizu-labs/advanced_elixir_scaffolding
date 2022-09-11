#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.IdentifierTypeBehaviour do
  @moduledoc """
  Entity handlers for ecto/identifier keys.
  - sref encoding,
  - validation
  - casting to redis/rdms appropriate format
  - etc.
  """
  
  @callback type() :: atom
  
  @doc """
  Check if provided value is correct for identifier type.
  """
  @callback __valid_identifier__(identifier :: any, configuration :: any) :: :ok | {:error, any}
  
  @doc """
  Prepare regex snippet for matching identifier
  """
  @callback __sref_section_regex__(configuration :: any) :: {:ok, String.t} | {:error, any}
  
  @doc """
  Encode valid identifier in string form for sref encoding.
  """
  @callback __id_to_string__(identifier :: any, configuration :: any) :: {:ok, String.t} | {:error, any}
  
  @doc """
  Decode string into identifier type.
  """
  @callback __string_to_id__(String.t, configuration :: any) :: {:ok, identifier :: any} | {:error, any}
end

defmodule Noizu.DomainObject.Atom.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :atom
  
  def __valid_identifier__(identifier, c) do
    cond do
      !is_atom(identifier) -> {:error, {:identifier, :expected_atom}}
      constraint = c[:constraint] ->
        case constraint do
          :existing -> :ok
          :any -> :ok
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
  
  def __sref_section_regex__(c) do
    v = cond do
          is_list(c[:constraint]) -> Enum.join(c[:constraint], "|")
          :else -> "[a-zA-Z0-9_]*"
        end
    {:ok, v}
  end
  
  def __id_to_string__(nil, c) do
    cond do
      c[:nil?] -> {:ok, Atom.to_string(nil)}
      :else -> {:error, {:identifier, :is_nil, nil}}
    end
  end
  def __id_to_string__(identifier, c) when is_atom(identifier) do
    cond do
      c[:constraint] == :existing -> {:ok, Atom.to_string(identifier)}
      c[:constraint] == nil -> {:error, :invalid_constraint}
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
  
  
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    cond do
      constraint = c[:constraint] ->
        case constraint do
          :existing -> {:ok, String.to_existing_atom(identifier)}
          :any -> {:ok, String.to_atom(identifier)}
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

defmodule Noizu.DomainObject.Float.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  
  def type(), do: :float
  
  def __valid_identifier__(identifier, c) do
    cond do
      !is_float(identifier) -> {:error, {:identifier, :expected_float}}
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
  
  
  def __sref_section_regex__(_c), do: {:ok, "-?[0-9]+\.[0-9]+"}
  
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_float(identifier), do: {:ok, Float.to_string(identifier)}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    case Float.parse(identifier) do
      {v, ""} ->
        case __valid_identifier__(v, c) do
          :ok -> {:ok, v}
          v -> v
        end
      v -> {:error, {:serialized_identifier, {:parse_failed, v}, identifier}}
    end
  end
end

defmodule Noizu.DomainObject.Hash.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :hash
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_bitstring(identifier) -> {:error, {:identifier, :expected_hash, identifier}}
      :else -> :ok
    end
  end
  
  
  def __sref_section_regex__(_c), do: {:ok, "[0-9a-zA-Z]+"}
  
  def __id_to_string__(nil, _c), do: {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_bitstring(identifier), do: {:ok, identifier}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, :expected_hash, identifier}}
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_hash, identifier}}
  def __string_to_id__(identifier, _c), do: {:ok, identifier}
end

defmodule Noizu.DomainObject.List.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :list
  
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
  
  def __sref_section_regex__(c) do
    element = __sref_inner__(c)
    {:ok, "\\[((" <> element <> "),?)+\\]"}
  end
  
  
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

defmodule Noizu.DomainObject.Integer.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  
  def type(), do: :integer
  
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

  
  def __sref_section_regex__(_c), do: {:ok, "-?[0-9]+"}
  
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_integer(identifier), do: {:ok, Integer.to_string(identifier)}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
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

defmodule Noizu.DomainObject.String.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :string
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_bitstring(identifier) -> {:error, {:identifier, :expected_string, identifier}}
      :else -> :ok
    end
  end

  
  def __sref_section_regex__(_c), do: {:ok, "\"[0-9a-zA-Z_\\-\\.]*\""}
  
  
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) when is_bitstring(identifier), do: {:ok, "\"#{identifier}\""}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, _c) do
    cond do
      String.starts_with?(identifier, "\"") && String.ends_with?(identifier, "\"") -> {:ok, String.slice(identifier, 1..-2)}
      :else -> {:error, :invalid_serialized_string}
    end
  end
end

defmodule Noizu.DomainObject.UUID.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :uuid
  
  def __valid_identifier__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, _} -> :ok
      {:error, d} -> {:error, {:identifier, {:invalid_uuid, d}, identifier}}
    end
  end

  def __sref_section_regex__(_c), do: {:ok, "[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"}
  
  def __id_to_string__(nil, _c), do:  {:error, {:identifier, :is_nil}}
  def __id_to_string__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, b} -> b[:type] == :default && {:ok, b[:uuid]} || {:ok, UUID.binary_to_string!(b[:binary])}
      {:error, d} -> {:error, {:identifier, {:invalid_uuid, d}, identifier}}
    end
  end
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_uuid, identifier}}
  def __string_to_id__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, d} ->
        cond do
          d[:type] == :default -> {:ok, d[:uuid]}
          :else -> {:ok, UUID.binary_to_string!(d[:binary])}
        end
      e -> {:error, {:serialized_identifier, {:invalid_uuid, e}, identifier}}
    end
  end
end




defmodule Noizu.DomainObject.IdentifierTypeResolver do
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


