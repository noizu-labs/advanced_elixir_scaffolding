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
  
  # Entity primary ked/id field
  @type identifier :: any
  
  # Identifier Type Configuration
  @type configuration :: any
  
  @callback type() :: atom
  
  @doc """
  Check if provided value is correct for identifier type.
  """
  @callback __valid_identifier__(identifier, configuration) :: :ok | {:error, any}
  
  @doc """
  Prepare regex snippet for matching identifier
  """
  @callback __sref_section_regex__(configuration) :: {:ok, String.t} | {:error, any}
  
  @doc """
  Encode valid identifier in string form for sref encoding.
  """
  @callback __id_to_string__(identifier, configuration) :: {:ok, String.t} | {:error, any}
  
  @doc """
  Decode string into identifier type.
  """
  @callback __string_to_id__(String.t, configuration) :: {:ok, identifier} | {:error, any}
end

defmodule Noizu.DomainObject.Integer.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :integer
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_integer(identifier) -> {:error, {:identifier, :expected_integer}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(_c), do: {:ok, "([0-9]*)"}
  
  def __id_to_string__(nil, _c), do: nil
  def __id_to_string__(identifier, _c) when is_integer(identifier), do: {:ok, Integer.to_string(identifier)}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, _c) do
    case Integer.parse(identifier) do
      {v, ""} -> {:ok, v}
      v -> {:error, {:serialized_identifier, {:parse_failed, v}, identifier}}
    end
  end


end

defmodule Noizu.DomainObject.String.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :string
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_bitstring(identifier) -> {:error, {:identifier, :expected_string, identifier}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(_c), do: {:ok, "([0-9a-zA-Z_-]*)"}
  
  
  def __id_to_string__(nil, _c), do: nil
  def __id_to_string__(identifier, _c) when is_bitstring(identifier), do: {:ok, identifier}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, _c), do: {:ok, identifier}
end

defmodule Noizu.DomainObject.Hash.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :hash
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_bitstring(identifier) -> {:error, {:identifier, :expected_hash, identifier}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(_c), do: {:ok, "([0-9a-zA-Z_-]*)"}
  
  def __id_to_string__(nil, _c), do: nil
  def __id_to_string__(identifier, _c) when is_bitstring(identifier), do: {:ok, identifier}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, :expected_hash, identifier}}
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_hash, identifier}}
  def __string_to_id__(identifier, _c), do: {:ok, identifier}
end

defmodule Noizu.DomainObject.UUID.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :uuid
  
  def __valid_identifier__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, _} -> :ok
      {:error, d} -> {:error, {:identifier, {:invalid_uuid, d}, identifier}}
    end
  end
  
  def __sref_section_regex__(_c), do: {:ok, "([0-9a-zA-Z\-]*)"}
  
  def __id_to_string__(nil, _c), do: nil
  def __id_to_string__(identifier, _c) do
    case UUID.info(identifier) do
      {:ok, b} -> b[:type] == :default && b[:uuid] || UUID.binary_to_string!(b[:binary])
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
      e -> {:errror, {:serialized_identifier, {:invalid_uuid, e}, identifier}}
    end
  end
end

defmodule Noizu.DomainObject.Atom.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :atom
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_atom(identifier) -> {:error, {:identifier, :expected_atom}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(c) do
    case c[:regex] do
      :auto ->
        v = c[:values] && Enum.join(c[:values], "|") || "[a-zA-Z0-9_]*"
        {:ok, "(#{v})"}
      v when is_bitstring(v) -> {:ok, "(#{v})"}
      v = %Regex{} ->  {:ok, "(#{v.source})"}
      nil -> {:ok, "([a-zA-Z0-9_]*)"}
      v -> {:error, {:configuration, :unsupported_regex, c}}
    end
  end
  
  def __id_to_string__(nil, c) do
    c[:nil?] -> {:ok, Atom.to_String(nil)}
    _ -> {:error, {:identifier, :is_nil, nil}}
  end
  def __id_to_string__(identifier, c) when is_atom(identifier) do
    cond do
      c[:constraint] == :existing -> {:ok, Atom.to_string(identifier)}
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
      _ -> {:ok, Atom.to_string(identifier)}
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
            Enum.find(v, &(:"#{&1}" == identifier)) || {:error, {:seriazed_identifier, :not_in_white_list, identifier}}
          v = %MapSet{} ->
            Enum.find(v, &(:"#{&1}" == identifier)) || {:error, {:seriazed_identifier, :not_in_white_list, identifier}}
          v when is_function(v, 0) -> v.()[identifier] && String.to_atom(identifier) || {:error, {:seriazed_identifier, :not_in_white_list, identifier}}
          v when is_function(v, 1) -> v.(identifier)  && String.to_atom(identifier) || {:error, {:seriazed_identifier, :not_in_white_list, identifier}}
          {m, f} -> apply(m, f, [identifier]) && String.to_atom(identifier) || {:error, {:seriazed_identifier, :not_in_white_list, identifier}}
          _ -> throw "invalid atom constraint #{inspect constraint}"
        end
      :else -> {:ok, String.to_existing_atom(identifier)}
    end
  end
end

defmodule Noizu.DomainObject.Ref.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :ref
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !(Kernel.match?({:ref, _, _}, identifier) || Kernel.match?({:ext_ref, _, _}, identifier))   -> {:error, {:identifier, :expected_ref_tup}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(_c), do: {:ok, "(ref\.[a-zA-Z0-9\-_]+\{[a-zA-Z_\-0-9@,.]+\}|ref\.[a-zA-Z0-9\-_]+\.[A-Za-z_\-0-9@.]+)"}
  def __id_to_string__(nil, _c), do: nil
  def __id_to_string__(identifier, c) do
    with {:ok, {_, m, _} = ref} <- Noizu.ERP.ref_ok(identifier),
         {:ok, sref} <- Noizu.ERP.sref_ok(identifier) do
      case constraint = c[:constraint] do
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
               v -> {:ok, v}
             end
    else
      e -> {:error, {:invalid_ref, e, identifier}}
    end
  end
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
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
      :else -> Noizu.ERP.ref_ok(identifier)
    end
  end
end

defmodule Noizu.DomainObject.Compound.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :compound
  
  def __valid_identifier__(identifier, _c) do
    cond do
      Kernel.match?({:ref, _, _}, identifier) -> {:error, {:identifier, :expected_compound}}
      !(is_list(identifier) || is_tuple(identifier)) -> {:error, {:identifier, :expected_compound}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(c) do
    cond do
      reg = c[:reg] when reg not in [nil, :auto] ->
        v = case reg do
              v when is_bitstring(v) -> v
              v = %Regex{} -> v.source
            end
        {:ok, "(\{#{v}\})"}
      template = c[:template] when is_tuple(template) ->
        inner = template
                |> Tuple.to_list()
                |> Enum.map(&(Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(&1)))
        {:ok, "(\{" <> Enum.join(inner, ",") <> "\})"}
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
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, c) do
    template = c[:template]
    cond do
      is_tuple(template) ->
        template_list = Tuple.to_list(template)
        extract = template_list
                  |> Enum.map(
                       fn(t) ->
                         {:ok, v} = Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(t)
                         v
                       end)
                  |> Enum.join(",")
        extract = Regex.compile("^{" <> extract <> "}")
        case Regex.run(extract, identifier) do
          [] -> {:error, {:serialized_identifier, {:regex_mismatch, extract.source}, identifier}}
          v when is_list(v) ->
            with true <- length(v) == length(template_list) || {:error, {:serialized_identifier, {:regex_mismatch, extract.source}, identifier}} do
              raw = for index <- 0..(length(template_list) - 1) do
                      {:ok, r} = Noizu.DomainObject.IdentifierTypeResolver.__string_to_id__(Enum.at(v, index), Enum.at(template_list, index))
                      r
                    end
                    |> List.to_tuple()
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
            else
              e -> e
            end
          _ -> {:error, {:serialized_identifier, {:regex_mismatch, extract.source}, identifier}}
        end
    end
  end
end

defmodule Noizu.DomainObject.List.IdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  
  def type(), :list
  
  def __valid_identifier__(identifier, _c) do
    cond do
      !is_list(identifier) -> {:error, {:identifier, :not_list}}
      :else -> :ok
    end
  end
  
  def __sref_section_regex__(c) do
    cond do
      reg = c[:reg] when reg not in [nil, :auto] ->
        v = case reg do
              v when is_bitstring(v) -> v
              v = %Regex{} -> v.source
            end
        {:ok, "(\[#{v}\])"}
      template = c[:template] when is_tuple(template) or is_atom(template) ->
        {:ok, inner} = Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(template)
        {:ok, "(\[((" <> inner <> ",?)+)\])"}
      :else -> {:ok, "(\[((,?)+)\])"}
    end
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
         r <- Regex.compile(raw) do
      case Regex.split(r, identifier, :include_captures) do
        v when is_list(v) and length(v) > 0 ->
          template = c[:template]
          v
          |> Enum.filter(&(!Enum.member?(["[", ",", "]"], &1)))
          |> Enum.map(&(Noizu.DomainObject.IdentifierTypeResolver.__string_to_id__(&1, template)))
        e -> {:error, {:invalid_serialized_identifier, e, identifier}}
      end
    else
      error -> {:error, {:invalid_serialized_identifier, error, identifier}}
    end
  end

end



defmodule Noizu.DomainObject.IdentifierTypeResolver do
  def __valid_identifier__(identifier, t), do: resolver(t, :__valid_identifier__, [identifier])
  def __sref_section_regex__(t), do: resolver(t, :__sref_section_regex__, [])
  def __id_to_string__(identifier, t), do: resolver(t, :__id_to_string__, [identifier])
  def __string_to_id__(serialized_identifier, t), do: resolver(t, :__string_to_id__, [serialized_identifier])
  
  def __built_in__() do
    %{
      integer: Noizu.DomainObject.Integer.IdentifierType,
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
  def __registered_types__() do
    __built_in__()
  end
  
  
  defp resolver(t, action, args) do
    {p, c} = case t do
               {p,c} -> {__registered_types__[p] || p, c}
               p when is_atom(p) -> {__registered_types__[p] || p, []}
             end
    apply(p, action, args ++ [c])
  rescue e -> {:error, {:rescue, e}}
  catch
    :exit, e -> {:error, {:exit, e}}
    e -> {:error, {:catch, e}}
  end
end


