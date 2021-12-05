#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Core.Entity.Implementation.Default do
  @moduledoc """
  Default Implementation.
  """


  #-----------------
  # has_permission
  #-------------------
  def has_permission?(_m, _ref, _permission, %{auth: auth}, _options) do
    auth[:permissions][:admin] || auth[:permissions][:system] || false
  end
  def has_permission?(_m, _ref, _permission, _context, _options), do: false

  #-----------------
  # has_permission!
  #-------------------
  def has_permission!(_m, _ref, _permission, %{auth: auth}, _options) do
    auth[:permissions][:admin] || auth[:permissions][:system] || false
  end
  def has_permission!(_m, _ref, _permission, _context, _options), do: false


  #-----------------
  # id
  #-----------------
  def id(domain_object, {:ref, domain_object, id}), do: id
  def id(domain_object, ref) do
    case domain_object.ref(ref) do
      {:ref, _, id} -> id
      _ -> nil
    end
  end

  #------------------
  # ref
  #------------------
  def ref(_domain_object, nil), do: nil
  def ref(domain_object, %{__struct__: domain_object, identifier: identifier}), do: {:ref, domain_object, identifier}
  def ref(domain_object, %{__struct__: associated_struct} = entity) do
    association_type = domain_object.__noizu_info__(:associated_types)[associated_struct]
    cond do
      association_type == nil -> nil
      association_type == false -> nil
      association_type == :poly -> associated_struct.ref(entity)
      config = domain_object.__persistence__(:tables)[associated_struct] ->
        identifier = case config.id_map do
                       :unsupported -> nil
                       :same -> get_in(entity, [Access.key(:identifier)]) || get_in(entity, [Access.key(:id)])
                       {m, f} -> apply(m, f, [entity])
                       {m, f, a} when is_list(a) -> apply(m, f, [entity] ++ a)
                       {m, f, a} -> apply(m, f, [entity, a])
                       f when is_function(f, 1) -> f.(entity)
                       _ -> nil
                     end
        identifier && {:ref, domain_object, identifier}
      :else -> nil
    end
  end
  def ref(domain_object, ref) when is_bitstring(ref) do
    ref = domain_object.__string_to_id__(ref)
    ref && domain_object.__valid_identifier__(ref) && {:ref, domain_object, ref}
  end
  def ref(domain_object, ref) do
    domain_object.__valid_identifier__(ref) && {:ref, domain_object, ref}
  end

  #------------------
  # sref
  #------------------
  def sref(domain_object, ref) do
    sref_name = domain_object.__sref__()
    identifier = domain_object.id(ref)
    cond do
      sref_name == :undefined -> nil
      identifier ->
        sref_identifier = case domain_object.__id_to_string__(identifier) do
                            {:ok, v} -> v
                            {:error, _} -> throw "#{domain_object}.__id_to_string__ failed for #{inspect identifier}"
                            v -> v || throw "#{domain_object}.__id_to_string__ failed for #{inspect identifier}"
                          end
        identifier_type = case domain_object.__noizu_info__(:identifier_type) do
                            identifier_type when is_tuple(identifier_type) -> elem(identifier_type, 0)
                            identifier_type -> identifier_type
                          end
        case identifier_type do
          :ref -> "ref.#{sref_name}{#{sref_identifier}}"
          :list -> "ref.#{sref_name}#{sref_identifier}"
          :compound -> "ref.#{sref_name}#{sref_identifier}"
          _other -> "ref.#{sref_name}.#{sref_identifier}"
        end
      :else -> nil
    end
  end

  #------------------
  # entity
  #------------------
  def entity(domain_object, %{__struct__: domain_object} = entity, _options), do: entity
  def entity(domain_object, %{__struct__: associated_struct} = entity, options) do
    association_type = domain_object.__noizu_info__(:associated_types)[associated_struct]
    cond do
      association_type == nil -> nil
      association_type == false -> nil
      association_type == :poly -> entity
      layer = domain_object.__persistence__(:tables)[associated_struct] ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__from_record__(layer, entity, context, options)
      :else -> nil
    end
  end
  def entity(domain_object, ref, options) do
    cond do
      ref = domain_object.id(ref) ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__repo__().get(ref, context, options)
      :else -> nil
    end
  end

  #------------------
  # entity!
  #------------------
  def entity!(domain_object, %{__struct__: domain_object} = entity, _options), do: entity
  def entity!(domain_object, %{__struct__: associated_struct} = entity, options) do
    association_type = domain_object.__noizu_info__(:associated_types)[associated_struct]
    cond do
      association_type == nil -> nil
      association_type == false -> nil
      association_type == :poly -> entity
      layer = domain_object.__persistence__(:tables)[associated_struct] ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__from_record__!(layer, entity, context, options)
      :else -> nil
    end
  end
  def entity!(domain_object, ref, options) do
    cond do
      ref = domain_object.id(ref) ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__repo__().get!(ref, context, options)
      :else -> nil
    end
  end

  #-----------------------------------
  # __sref_section_regex__
  #-----------------------------------
  def __sref_section_regex__(_, :integer), do: "([0-9]*)"
  def __sref_section_regex__(_, :string), do: "([0-9a-zA-Z_-]*)"
  def __sref_section_regex__(_, :hash), do: "([0-9a-zA-Z_-]*)"
  def __sref_section_regex__(_, :uuid), do: "([0-9a-zA-Z_-]*)"
  def __sref_section_regex__(m, {:list, template}), do: "(\[((" <> m.__sref_section_regex__(template) <> ",?)+)\])"
  def __sref_section_regex__(m, {:compound, template, _}), do: m.__sref_section_regex__({:compound, template})
  def __sref_section_regex__(m, {:compound, template}), do: "(\{" <> Enum.join(Enum.map(template, &(m.__sref_section_regex__(&1))), ",") <> "\})"
  def __sref_section_regex__(m, {:atom, _c}), do: m.__sref_section_regex__(:atom)
  def __sref_section_regex__(_, :atom), do: "([a-z_A-Z0-9]*)"
  def __sref_section_regex__(m, {:ref, _c}), do: m.__sref_section_regex__(:ref)
  def __sref_section_regex__(_, :ref), do: "(ref\.[a-z0-9\-]+\{[a-z_\-0-9@,.]+\}|ref\.[a-z0-9\-]+\.[a-z_\-0-9@.]+)"

  #-----------------------------------
  # __id_to_string__
  #-----------------------------------
  def __id_to_string__(_m, _, nil), do: nil
  def __id_to_string__(_m, :integer, id) when is_integer(id), do: {:ok, Integer.to_string(id)}
  def __id_to_string__(_m, :string, id) when is_bitstring(id), do: {:ok, id}
  def __id_to_string__(_m, :hash, id) when is_bitstring(id), do: {:ok, id}
  def __id_to_string__(_m, :uuid, id), do: {:ok, UUID.binary_to_string!(id)}
  def __id_to_string__(m, {:list, template}, id) do
    v = "[" <> (
                 Enum.map(id, &(m.__id_to_string__(template, &1)))
                 |> Enum.join(",")) <> "]"
    {:ok, v}
  end
  def __id_to_string__(m, {:compound, template, prep}, id) do
    case prep do
      prep when is_function(prep, 2) -> m.__id_to_string__({:compound, template}, prep.(:encode, id))
      {m, f} -> m.__id_to_string__({:compound, template}, apply(m, f, [:encode, id]))
      _ -> throw "invalid compound id formatter"
    end
  end
  def __id_to_string__(m, {:compound, template}, id) do
    template_list = Tuple.to_list(template)
    id_list = Tuple.to_list(id)
    length(template_list) != length(id_list) && throw "invalid compound id #{inspect id}"
    l = Enum.map_reduce(id_list, 0, &({m.__id_to_string__(Enum.at(template_list, &2), &1), &2 + 1}))
    {:ok, "{" <> Enum.join(l, ",") <> "}"}
  end
  def __id_to_string__(_m, :atom, id), do: {:ok, Atom.to_string(id)}
  def __id_to_string__(_m, {:atom, :existing}, id), do: {:ok, Atom.to_string(id)}
  def __id_to_string__(_m, {:atom, constraint}, id) do
    sref = case constraint do
             v when is_list(v) -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v = %MapSet{} -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 0) -> v.()[id] && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 1) -> v.(id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             {m, f} -> apply(m, f, [id]) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             _ -> throw "invalid atom constraint #{inspect constraint}"
           end
    {:ok, "[#{sref}]"}
  end
  def __id_to_string__(_m, :ref, id) do
    if v = Noizu.ERP.sref(id) do
      {:ok, v}
    else
      throw "invalid ref"
    end
  end
  def __id_to_string__(_m, {:ref, constraint}, id) do
    m = case Noizu.ERP.ref(id) do
          {:ref, m, _} -> m
          _else -> throw "invalid ref"
        end
    sref = Noizu.ERP.sref(id) || throw "invalid ref"
    v = case constraint do
          v when is_list(v) -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
          v = %MapSet{} -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
          v when is_function(v, 0) -> v.()[m] && sref || throw "unsupported ref id #{inspect sref}"
          v when is_function(v, 1) -> v.(m) && sref || throw "unsupported ref id #{inspect sref}"
          {m, f} -> apply(m, f, [m]) && sref || throw "unsupported ref id #{inspect sref}"
          _ -> throw "invalid ref constraint #{inspect constraint}"
        end
    {:ok, v}
  end

  #-----------------------------------
  # __string_to_id__
  #-----------------------------------
  def __string_to_id__(_m, _, nil), do: nil
  def __string_to_id__(_m, _, id) when not is_bitstring(id), do: throw "invalid sref id part #{inspect id}"
  def __string_to_id__(_m, :integer, id) do
    case Integer.parse(id) do
      {v, ""} -> v
      :error -> nil
      _ -> nil
    end
  end
  def __string_to_id__(_m, :string, id), do: id
  def __string_to_id__(_m, :hash, id), do: id
  def __string_to_id__(_m, :uuid, id), do: UUID.string_to_binary!(id)
  def __string_to_id__(m, {:list, template}, id) do
    r = Regex.compile(m.__sref_section_regex__(template))
    case Regex.split(r, id, :include_captures) do
      v when is_list(v) and length(v) > 0 ->
        Enum.filter(v, &(!Enum.member?(["[", ",", "]"], &1)))
        |> Enum.map(&(m.__string_to_id__(template, &1)))
      _ -> throw "invalid sref id part #{inspect id}"
    end
  end
  def __string_to_id__(m, {:compound, template, prep}, id) do
    formatted = m.__string_to_id__({:compound, template}, id)
    case prep do
      prep when is_function(prep, 2) -> prep.(:decode, formatted)
      {m, f} -> apply(m, f, [:decode, formatted])
      _ -> throw "invalid compound id formatter"
    end
  end
  def __string_to_id__(m, {:compound, template}, id) do
    template_list = Tuple.to_list(template)
    id_list = Tuple.to_list(id)
    length(template_list) != length(id_list) && throw "invalid compound id #{inspect id}"
    extract = Enum.map(template, &(m.__sref_section_regex__(&1)))
              |> Enum.join(",")
    extract = Regex.compile("^{" <> extract <> "}")
    case Regex.run(extract, id) do
      nil -> throw "invalid compound id #{extract.source}"
      [] -> throw "invalid compound id #{extract.source}"
      v when is_list(v) ->
        length(v) != length(template_list) && throw "malformed compound id: #{inspect id}"
        Enum.map(v, &(m.__string_to_id__(Enum.at(template_list, &2), &1)))
        |> List.to_tuple()
    end
  end
  def __string_to_id__(_m, :atom, id), do: Atom.to_string(id)
  def __string_to_id__(_m, {:atom, :existing}, id), do: Atom.to_string(id)
  def __string_to_id__(_m, {:atom, constraint}, id) do
    sref = case constraint do
             v when is_list(v) -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v = %MapSet{} -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 0) -> v.()[id] && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 1) -> v.(id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             {m, f} -> apply(m, f, [id]) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             _ -> throw "invalid atom constraint #{inspect constraint}"
           end
    "[#{sref}]"
  end
  def __string_to_id__(_m, :ref, id), do: Noizu.ERP.sref(id) || throw "invalid ref"
  def __string_to_id__(_m, {:ref, constraint}, id) do
    m = case Noizu.ERP.ref(id) do
          {:ref, m, _} -> m
          _else -> throw "invalid ref"
        end
    sref = Noizu.ERP.sref(id) || throw "invalid ref"
    case constraint do
      v when is_list(v) -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v = %MapSet{} -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 0) -> v.()[m] && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 1) -> v.(m) && sref || throw "unsupported ref id #{inspect sref}"
      {m, f} -> apply(m, f, [m]) && sref || throw "unsupported ref id #{inspect sref}"
      _ -> throw "invalid ref constraint #{inspect constraint}"
    end
  end

  def __valid__(m, entity, context, options) do
    attributes = m.__noizu_info__(:field_attributes)
    field_errors = Enum.map(
                     Map.from_struct(entity),
                     fn ({field, value}) ->
                       # Required Check
                       field_attributes = attributes[field]
                       required = field_attributes[:required]
                       required_check = case required do
                                          true -> (value && true) || {:error, {:required, field}}
                                          {m, f} ->
                                            arity = Enum.max(Keyword.get_values(m.__info__(:functions), f))
                                            case arity do
                                              1 -> apply(m, f, [value])
                                              2 -> apply(m, f, [field, entity])
                                              3 -> apply(m, f, [field, entity, context])
                                              4 -> apply(m, f, [field, entity, context, options])
                                            end
                                          {m, f, arity} when is_integer(arity) ->
                                            case arity do
                                              1 -> apply(m, f, [value])
                                              2 -> apply(m, f, [field, entity])
                                              3 -> apply(m, f, [field, entity, context])
                                              4 -> apply(m, f, [field, entity, context, options])
                                            end
                                          {m, f, a} when is_list(a) -> apply(m, f, [field, entity] ++ a)
                                          {m, f, a} -> apply(m, f, [field, entity, a])
                                          f when is_function(f, 1) -> f.([value])
                                          f when is_function(f, 2) -> f.([field, entity])
                                          f when is_function(f, 3) -> f.([field, entity, context])
                                          f when is_function(f, 4) -> f.([field, entity, context, options])
                                          false -> true
                                          nil -> true
                                        end

                       # Type Constraint Check
                       type_constraint_check = case field_attributes[:type_constraint] do
                                                 {:ref, permitted} ->
                                                   case value do
                                                     {:ref, domain_object, _identifier} ->
                                                       (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:ref, {field, domain_object}}}
                                                     %{__struct__: domain_object} ->
                                                       (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:ref, {field, domain_object}}}
                                                     nil ->
                                                       cond do
                                                         required == true -> {:error, {:ref, {field, value}}}
                                                         :else -> true
                                                       end
                                                     _ ->
                                                       {:error, {:ref, {field, value}}}
                                                   end
                                                 {:struct, permitted} ->
                                                   case value do
                                                     %{__struct__: domain_object} ->
                                                       (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:struct, {field, domain_object}}}
                                                     nil ->
                                                       cond do
                                                         required == true -> {:error, {:struct, {field, value}}}
                                                         :else -> true
                                                       end
                                                     _ ->
                                                       {:error, {:struct, {field, value}}}
                                                   end
                                                 {:enum, permitted} ->
                                                   et = permitted.__enum_type__
                                                   ee = permitted.__entity__
                                                   case value do
                                                     nil ->
                                                       cond do
                                                         required == true -> {:error, {:enum, {field, value}}}
                                                         :else -> true
                                                       end
                                                     {:ref, ^ee, _identifier} -> true
                                                     %{__struct__: ^ee} -> true
                                                     # %^ee{} breaks intellij parsing.
                                                     v when is_atom(v) -> et && Map.has_key?(et.atom_to_enum(), value) || {:error, {:enum, {field, value}}}
                                                     _ -> {:error, {:enum, {field, value}}}
                                                   end
                                                 {:atom, permitted} ->
                                                   case value do
                                                     nil ->
                                                       cond do
                                                         required == true -> {:error, {:enum, {field, value}}}
                                                         :else -> true
                                                       end
                                                     v when is_atom(v) -> (permitted == :any || Enum.member?(permitted, v)) || {:error, {:enum, {field, value}}}
                                                     _ -> {:error, {:enum, {field, value}}}
                                                   end
                                                 _ -> true
                                               end

                       errors = Enum.filter(
                         [required_check, type_constraint_check],
                         fn (v) ->
                           case v do
                             {:error, _} -> true
                             _ -> false
                           end
                         end
                       )
                       length(errors) > 0 && {field, errors} || nil
                     end
                   )
                   |> Enum.filter(&(&1))

    cond do
      field_errors == [] -> true
      :else -> {:error, Map.new(field_errors)}
    end
  end


end
