#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Entity do
  @moduledoc """
    Provides scaffolding for DomainObject.Entity
    @todo simplify how extensions (like kitchen sink CMS extensions) are applied.
  """
  
  defmodule Behaviour do
    alias Noizu.AdvancedScaffolding.Types

    #---------------------------------------------------------------------------------------------
    # core
    #---------------------------------------------------------------------------------------------

    @callback __sref_prefix__() :: String.t
    
    @callback has_permission?(any, any, any, any) :: boolean
    @callback has_permission!(any, any, any, any) :: boolean
  
    @callback version_change(any, any, any) :: any
    @callback version_change(any, any, any, any) :: any
  
    @callback version_change!(any, any, any) :: any
    @callback version_change!(any, any, any, any) :: any
  
    @callback vsn() :: float
    @callback __entity__() :: module
    @callback __base__() :: module
    @callback __poly_base__() :: module
    @callback __repo__() :: module
    @callback __sref__() :: String.t
    @callback __erp__() :: module
    @callback __sref_prefix__() :: String.t
  
    @callback __valid_identifier__(any) :: boolean
    @callback __id_to_string__(Types.identifier_type) :: boolean
    @callback __string_to_id__(Types.identifier_type) :: boolean
  
  
    @callback __valid__(any, any, any) :: any
  
    @callback id(Types.entity_or_ref) :: Types.entity_identifier
    @callback ref(Types.entity_or_ref) :: Types.ref
    @callback sref(Types.entity_or_ref) :: Types.sref
    @callback entity(Types.entity_or_ref) :: map() | nil
    @callback entity(Types.entity_or_ref, Types.options) :: map() | nil
    @callback entity!(Types.entity_or_ref) :: map() | nil
    @callback entity!(Types.entity_or_ref, Types.options) :: map() | nil
  
    @callback __noizu_info__() :: any
    @callback __noizu_info__(any) :: any
  
    @callback __fields__() :: any
    @callback __fields__(any) :: any
  
    @callback __enum__() :: any
    @callback __enum__(any) :: any


    #---------------------------------------------------------------------------------------------
    # Persistence
    #---------------------------------------------------------------------------------------------

    @callback ecto_entity?() :: boolean
    @callback source(any) :: any
    @callback universal_identifier(Types.entity_or_ref) :: nil | integer
    @callback ecto_identifier(Types.entity_or_ref) :: integer | nil

    @callback __as_record__(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil
    @callback __as_record__!(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil

    @callback __as_record_type__(any, any, any) :: any
    @callback __as_record_type__(any, any, any, any) :: any

    @callback __as_record_type__!(any, any, any) :: any
    @callback __as_record_type__!(any, any, any, any) :: any

    @callback __from_record__(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil
    @callback __from_record__!(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil
    
    @callback __persistence__() :: any
    @callback __persistence__(any) :: any
    @callback __persistence__(any, any) :: any

    @callback __nmid__() :: any
    @callback __nmid__(any) :: any
  
    #---------------------------------------------------------------------------------------------
    # Index
    #---------------------------------------------------------------------------------------------
    @callback __write_indexes__(any, any, any) :: any
    @callback __update_indexes__(any, any, any) :: any
    @callback __delete_indexes__(any, any, any) :: any

    @callback __write_index__(any, any, any, any, any) :: any
    @callback __update_index__(any, any, any, any, any) :: any
    @callback __delete_index__(any, any, any, any, any) :: any

    @callback __indexing__() :: any
    @callback __indexing__(any) :: any
  
    #---------------------------------------------------------------------------------------------
    # Json
    #---------------------------------------------------------------------------------------------
    @callback __strip_pii__(any, any) :: any
    @callback __json__() :: any
    @callback __json__(any) :: any
    @callback from_json(format :: any, json :: any, context :: any, options :: any) :: map() | {:error, atom | tuple}
  
    
    #---------------------------------------------------------------------------------------------
    # Inspect
    #---------------------------------------------------------------------------------------------
    @callback __strip_inspect__(any, any) :: any

  end
  
  defmodule Default do
    @moduledoc """
    Default Implementation.
    """
    require Logger
    alias Giza.SphinxQL
    alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer


    @pii_levels %{
      level_0: 0,
      level_1: 1,
      level_2: 2,
      level_3: 3,
      level_4: 4,
      level_5: 5,
      level_6: 6,
      default: 6,
    }

    #---------------------------------------------------------------------------------------------
    # Core
    #---------------------------------------------------------------------------------------------

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
  
    def ref(domain_object, identifier) do
      case domain_object.ref_ok(identifier) do
        {:ok, v} -> v
        _ -> nil
      end
    end
  
    #------------------
    # ref_ok
    #------------------
    def ref_ok(_domain_object, nil), do: {:error, {:identifier, :is_nil}}
    def ref_ok(domain_object, %{__struct__: domain_object, identifier: identifier}), do: {:ok, {:ref, domain_object, identifier}}
    def ref_ok(domain_object, %{__struct__: associated_struct} = entity) do
      association_type = domain_object.__noizu_info__(:associated_types)[associated_struct]
      cond do
        association_type == nil -> {:error, {:unsupported_ref, associated_struct}}
        association_type == false -> {:error, {:unsupported_ref, associated_struct}}
        association_type == :poly -> associated_struct.ref_ok(entity)
        config = domain_object.__persistence__(:tables)[associated_struct] ->
          case config.id_map do
            :unsupported -> {:error, :unsupported_ref}
            :same -> get_in(entity, [Access.key(:identifier)]) || get_in(entity, [Access.key(:id)])
            {m, f} -> apply(m, f, [entity])
            {m, f, a} when is_list(a) -> apply(m, f, [entity] ++ a)
            {m, f, a} -> apply(m, f, [entity, a])
            f when is_function(f, 1) -> f.(entity)
            _ -> nil
          end
          |> case do
               nil -> {:error, {:unsupported_ref, associated_struct}}
               e = {:error, _} -> e
               v -> {:ok, {:ref, domain_object, v}}
             end
        :else -> {:error, {:unsupported_ref, associated_struct}}
      end
    end
  
    # UUID special handler
    def ref_ok(domain_object, <<v::binary-size(16)>>), do: ref_ok(domain_object, {:ref, domain_object, v})
    def ref_ok(domain_object, v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>>), do: ref_ok(domain_object, {:ref, domain_object, UUID.string_to_binary!(v)})
    # SREF
    def ref_ok(domain_object, ref) when is_bitstring(ref) do
      sref_name = domain_object.__sref__()
      ref = cond do
              String.starts_with?(ref, "ref.#{sref_name}.") -> String.slice(ref, length("ref.#{sref_name}.")..-1)
              String.starts_with?(ref, "ref.#{sref_name}") -> String.slice(ref, length("ref.#{sref_name}")..-1)
              :else -> ref
            end
      with {:ok, id} <- domain_object.__string_to_id__(ref),
           :ok <- domain_object.__valid_identifier__(id) do
        {:ok, {:ref, domain_object, id}}
      else
        e -> e
      end
    end
    def ref_ok(domain_object, {:ref, domain_object, id}) do
      case domain_object.__valid_identifier__(id) do
        :ok -> {:ok, {:ref, domain_object, id}}
        e -> e
      end
    end
    def ref_ok(domain_object, ref) do
      case domain_object.__valid_identifier__(ref) do
        :ok -> {:ok, {:ref, domain_object, ref}}
        e -> e
      end
    end
  
    #------------------
    # sref
    #------------------
    def sref(domain_object, ref) do
      case sref_ok(domain_object, ref) do
        {:ok, v} -> v
        _ -> nil
      end
    end
  
    #------------------
    # sref_ok
    #------------------
    def sref_ok(domain_object, ref) do
      sref_name = domain_object.__sref__()
      identifier = domain_object.id(ref)
      cond do
        sref_name == :undefined -> {:error, {:sref_module_undefined, domain_object}}
        identifier ->
          case domain_object.__id_to_string__(identifier) do
            {:ok, v} -> {:ok, "ref.#{sref_name}.#{v}"}
            e -> e
          end
        :else -> {:error, {:identifier, nil}}
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

    #---------------------------------------------------------------------------------------------
    # Index
    #---------------------------------------------------------------------------------------------
    def __write_index__(domain_object, entity, index, settings, context, options) do
      IO.puts "WRITE INDEX: #{inspect domain_object} . . ."
      cond do
        settings[:options][:type] == :real_time ->
          cond do
            index.__index_supported__?(:real_time, context, options) ->
              # @todo tweak header, return raw fields or only field lists not the replace statement.
              replace = index.__index_header__(:real_time, context, options)
              fields = index.__index_record__(:real_time, entity, context, options) # todo merge options / settings. E.g. for locale randomization etc.
              record = Enum.join(fields, " ,")
              query = replace <> " (" <> record <> ") "
              IO.puts "SPHINX QUERY| #{query}"
              SphinxQL.new() |> SphinxQL.raw(query) |> SphinxQL.send() |> IO.inspect()
            :else ->
              IO.puts ":real_time NOT SUPPORTED"
              :unsupported
          end
        :else ->
          IO.puts "TODO - #{domain_object} - Perform record keeping so entity's can be reindexed/delta-indexed. etc."
          :nyi
      end
    end
    def __update_index__(domain_object, entity, index, settings, context, options) do
      IO.puts "UPDATE INDEX: #{inspect domain_object}"
      cond do
        settings[:options][:type] == :real_time ->
          cond do
            index.__index_supported__?(:real_time, context, options) ->
              replace = index.__index_header__(:real_time, context, options)
              fields = index.__index_record__(:real_time, entity, context, options) # todo merge options / settings. E.g. for locale randomization etc.
              record = Enum.join(fields, " ,")
              query = replace <> " (" <> record <> ") "
              Logger.info "SPHINX QUERY| #{query}"
              SphinxQL.new() |> SphinxQL.raw(query) |> SphinxQL.send()
            :else -> :unsupported
          end
        :else ->
          IO.puts "TODO - Perform record keeping so entity's can be reindexed/delta-indexed. etc."
          :nyi
      end
    end
    def __delete_index__(domain_object, _entity, _index, _settings, _context, _options) do
      # needed
      IO.puts "DELETE INDEX: #{inspect domain_object}"
      IO.puts "TODO - #{domain_object} - iterate over indexes (if any) and call their delete methods."
      :nyi
    end
  
    #---------------------------------------------------------------------------------------------
    # Persistence
    #---------------------------------------------------------------------------------------------

    #-----------------------------------
    # __as_record__
    #-----------------------------------
    def __as_record__(domain_object, table, ref, context, options) when is_atom(table) do
      layer = domain_object.__persistence__(:table)[table]
      layer && domain_object.__as_record__(layer, ref, context, options)
    end
    def __as_record__(domain_object, layer = %{__struct__: PersistenceLayer}, ref, context, options) do
      cond do
        entity = domain_object.entity(ref, options) -> __as_record_type__(domain_object, layer, entity, context, options)
        :else -> nil
      end
    end

    #-----------------------------------
    # __as_record__!
    #-----------------------------------
    def __as_record__!(domain_object, table, ref, context, options) when is_atom(table) do
      layer = domain_object.__persistence__(:table)[table]
      layer && domain_object.__as_record__!(layer, ref, context, options)
    end
    def __as_record__!(domain_object, layer = %{__struct__: PersistenceLayer}, ref, context, options) do
      cond do
        entity = domain_object.entity(ref, options) -> __as_record_type__(domain_object, layer, entity, context, options)
        :else -> nil
      end
    end

    def strip_transient(entity) do
      struct(entity.__struct__, Map.from_struct(entity) |> Map.drop(entity.__struct__.__fields__(:transient)))
    end

    #-----------------------------------
    # __as_record_type__
    #-----------------------------------
    def __as_record_type__(domain_object, layer = %{__struct__: PersistenceLayer, type: :mnesia, table: table}, entity, context, options) do
      context = Noizu.ElixirCore.CallingContext.system(context)
      field_types = domain_object.__noizu_info__(:field_types)
      fields = Map.keys(struct(table.__struct__(), [])) -- [:__struct__, :__transient__, :__initial__]
      embed_fields = Enum.map(
                       fields,
                       fn (field) ->
                         cond do
                           field == :identifier -> {field, entity.identifier}
                           field == :entity ->
                             # Transient fields are stripped here for the embedded entry as TypeHandlers may require transient details to correctly unpack.
                             {field, strip_transient(entity)}
                           entry = layer.schema_fields[field] ->
                             type = field_types[entry[:source]]
                             source = case entry[:selector] do
                                        nil -> get_in(entity, [Access.key(entry[:source])])
                                        path when is_list(path) -> get_in(entity, path)
                                        {m, f, a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                                        {m, f, a} -> apply(m, f, [entry, entity, a])
                                        f when is_function(f, 0) -> f.()
                                        f when is_function(f, 1) -> f.(entity)
                                        f when is_function(f, 2) -> f.(entry, entity)
                                        f when is_function(f, 3) -> f.(entry, entity, context)
                                        f when is_function(f, 4) -> f.(entry, entity, context, options)
                                      end
                             type.handler.dump(entry[:source], entry[:segment], source, type, layer, context, options)
                           Map.has_key?(entity, field) -> {field, get_in(entity, [Access.key(field)])}
                           :else -> nil
                         end
                       end
                     )
                     |> List.flatten()
                     |> Enum.filter(&(&1))
  
      struct(layer.table.__struct__(), embed_fields)
    end
    def __as_record_type__(_domain_object, _layer = %{type: :redis}, entity, _context, _options) do
      strip_transient(entity)
    end
    def __as_record_type__(domain_object, layer = %{type: :ecto, table: table}, entity, _context, options) do
      context = Noizu.ElixirCore.CallingContext.admin()
      field_types = domain_object.__noizu_info__(:field_types)
      embed_fields = Enum.map(
                       domain_object.__fields__(:persisted),
                       fn (field) ->
                         cond do
                           field == :identifier ->
                             case Noizu.EctoEntity.Protocol.ecto_identifier(entity) do
                               v when is_list(v) -> v
                               v -> {:identifier, v}
                             end
                           entry = layer.schema_fields[field] ->
                             type = field_types[entry[:source]]
                             source = case entry[:selector] do
                                        nil -> get_in(entity, [Access.key(entry[:source])])
                                        path when is_list(path) -> get_in(entity, path)
                                        {m, f, a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                                        {m, f, a} -> apply(m, f, [entry, entity, a])
                                        f when is_function(f, 0) -> f.()
                                        f when is_function(f, 1) -> f.(entity)
                                        f when is_function(f, 2) -> f.(entry, entity)
                                        f when is_function(f, 3) -> f.(entry, entity, context)
                                        f when is_function(f, 4) -> f.(entry, entity, context, options)
                                      end
                             type.handler.dump(entry[:source], entry[:segment], source, type, layer, context, options)
                           Map.has_key?(entity, field) -> {field, get_in(entity, [Access.key(field)])}
                           :else -> nil
                         end
                       end
                     )
                     |> List.flatten()
                     |> Enum.filter(&(&1))
  
      struct(table.__struct__(), embed_fields)
    end

    def __as_record_type__(_domain_object, _layer, _entity, _context, _options), do: nil

    #-----------------------------------
    # __as_record_type__!
    #-----------------------------------
    def __as_record_type__!(domain_object, layer, entity, context, options), do: __as_record_type__(domain_object, layer, entity, context, options)


    #-----------------------------------
    #
    #-----------------------------------
    def __from_record__(_domain_object, _layer, %{entity: temp}, _context, _options) do
      temp
    end
    def __from_record__(_domain_object, :redis, ref, _context, _options) do
      ref
    end
    def __from_record__(_domain_object, %{type: :redis}, ref, _context, _options) do
      ref
    end
    def __from_record__(_domain_object, _layer, _ref, _context, _options) do
      nil
    end

    def __from_record__!(_domain_object, _layer, %{entity: temp}, _context, _options) do
      temp
    end
    def __from_record__!(_domain_object, :redis, ref, _context, _options) do
      ref
    end
    def __from_record__!(_domain_object, %{type: :redis}, ref, _context, _options) do
      ref
    end
    def __from_record__!(_domain_object, _layer, _ref, _context, _options) do
      nil
    end

    #-----------------------------------
    #
    #-----------------------------------
    def ecto_identifier(_, %{ecto_identifier: id}), do: id
    def ecto_identifier(_, %{identifier: id}) when is_integer(id), do: id
    def ecto_identifier(m, ref) do
      ref = m.ref(ref)
      case Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table.read!(ref) do
        %{__struct__: Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table, ecto_identifier: id} -> id
        _ ->
          case m.entity(ref) do
            %{ecto_identifier: id} ->
              Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table.write!(%{__struct__: Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table, identifier: ref, ecto_identifier: id})
              id
            _ -> nil
          end
      end
    end

    #-----------------------------------
    #
    #-----------------------------------
    def universal_identifier_lookup(m, ref) do
      ref = m.ref(ref)
      case Noizu.AdvancedScaffolding.Database.UniversalLookup.Table.read!(ref) do
        %{__struct__: Noizu.AdvancedScaffolding.Database.UniversalLookup.Table, universal_identifier: id} -> id
      end
    end
    
    #---------------------------------------------------------------------------------------------
    # Json
    #---------------------------------------------------------------------------------------------
    def __strip_pii__(_m, entity, max_level) do
      max_level = @pii_levels[max_level] || @pii_levels[:level_3]
      v = Enum.map(
        Map.from_struct(entity),
        fn ({field, value}) ->
          cond do
            (@pii_levels[entity.__struct__.__noizu_info__(:field_attributes)[field][:pii]]) >= max_level -> {field, value}
            :else -> {field, :"*RESTRICTED*"}
          end
        end
      )
      struct(entity.__struct__, v)
    end

    def from_json(m, format, json, context, options) do
      field_types = m.__noizu_info__(:field_types)
      fields = Map.keys(struct(m.__struct__(), [])) -- [:__struct__, :__transient__, :initial]
      full_kind = Atom.to_string(m)
      partial_kind = String.split(full_kind, ".") |> String.slice(-2 .. -1) |> Enum.join(".")
      if json["kind"] == full_kind || json["kind"] == partial_kind do
        # todo if entity identifier is set then we should load the existing entity and only apply the delta here,
        Enum.map(
          fields,
          fn (field) ->
            # @todo check for a json as clause
            v = json[Atom.to_string(field)]
            cond do
              type = field_types[field] ->
                {field, type.handler.from_json(format, v, context, options)}
              :else -> {field, v}
            end
          end
        )
        |> m.__struct__()
      end
    end
    
    #---------------------------------------------------------------------------------------------
    # Inspect
    #---------------------------------------------------------------------------------------------
    def __strip_inspect__(_m, entity, opts) do
      field_types = entity.__struct__.__noizu_info__(:field_types)
      Enum.map(
        Map.from_struct(entity),
        fn ({field, value}) ->
          cond do
            value == :"*RESTRICTED*" -> {field, value}
            entity.__struct__.__noizu_info__(:field_attributes)[field][:inspect][:ignore] -> nil
            type = field_types[field] -> type.handler.__strip_inspect__(field, value, opts)
            entity.__struct__.__noizu_info__(:field_attributes)[field][:inspect][:ref] -> {field, Noizu.ERP.ref(value)}
            entity.__struct__.__noizu_info__(:field_attributes)[field][:inspect][:sref] -> {field, Noizu.ERP.sref(value)}
            :else -> {field, value}
          end
        end
      )
      |> Enum.filter(&(&1))
      |> Map.new()
    end
    
  end
  
  #--------------------------------------------
  # __noizu_entity__/3
  #--------------------------------------------
  @doc """
  Initialize a DomainObject.Entity. Caller passes in identifier and field definitions which are in turn used to generate the domain object entity's configuration options and defstruct statement.
  """
  def __noizu_entity__(caller, options, block) do


    extension_provider = options[:extension_implementation] || nil
    extension_block_a = extension_provider && quote do: (use unquote(extension_provider), unquote(options))
    extension_block_b = extension_provider && extension_provider.pre_defstruct(options)
    extension_block_c = extension_provider && extension_provider.post_defstruct(options)
    extension_block_d = extension_provider && quote do
                                                @before_compile unquote(extension_provider)
                                                @after_compile  unquote(extension_provider)
                                              end

    configuration = Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.__configure__(options)
    implementation = Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.__implement__(options)
    
    process_config = quote do
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       require Noizu.DomainObject
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros
                       require Noizu.AdvancedScaffolding.Internal.Helpers
                       import Noizu.ElixirCore.Guards
                       @options unquote(options)
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__entity_defined, unquote(caller))

                       #--------------------
                       # Extract configuration details from provided options/set attributes/base attributes/config methods.
                       #--------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(configuration)
                       
                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       # Prep attributes for loading individual fields.
                       @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
                       Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros.__register__field_attributes__macro__(unquote(options))

                       try do
                         @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                         # we rely on the same providers as used in the Entity type for providing json encoding, restrictions, etc.
                         import Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros, only: [
                           identifier: 0, identifier: 1, identifier: 2,
                           ecto_identifier: 0, ecto_identifier: 1, ecto_identifier: 2,
                           public_field: 1, public_field: 2, public_field: 3, public_fields: 1, public_fields: 2,
                           restricted_field: 1, restricted_field: 2, restricted_field: 3, restricted_fields: 1, restricted_fields: 2,
                           private_field: 1, private_field: 2, private_field: 3, private_fields: 1, private_fields: 2,
                           internal_field: 1, internal_field: 2, internal_field: 3, internal_fields: 1, internal_fields: 2,
                           transient_field: 1, transient_field: 2, transient_field: 3, transient_fields: 1, transient_fields: 2,
                         ]
                         @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                         unquote(extension_block_a)
                         @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                         unquote(block)
                       after
                         :ok
                       end
                       unquote(extension_block_b)
                       Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros.__post_struct_definition_macro__(unquote(options))
                     end

    generate = quote unquote: false do
                 #@derive @__nzdo__derive
                 def __nzdo__derive__(), do: @__nzdo__derive
                 defstruct @__nzdo__fields
               end
    quote do
      __nzdo_prof__s01 = :os.system_time(:millisecond)
      
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      unquote(process_config)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(generate)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(implementation)
      
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(extension_block_c)

      @before_compile Noizu.AdvancedScaffolding.Internal.DomainObject.Entity
      @after_compile Noizu.AdvancedScaffolding.Internal.DomainObject.Entity

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      unquote(extension_block_d)

      __nzdo_prof__e01 = :os.system_time(:millisecond)
      if ((__nzdo_prof__e01 - __nzdo_prof__s01) > 500), do: IO.puts "#{__MODULE__}:#{unquote(__ENV__.line)} - slow compile time #{(__nzdo_prof__e01 - __nzdo_prof__s01)} ms"
      
      @file __ENV__.file
    end
  end





  def __configure__(options) do
    quote do
      #---------------------------------------------------------------------------------------------
      # core
      #---------------------------------------------------------------------------------------------
  
      # Extract Base Fields fields since SimbpleObjects are at the same level as their base.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__base__macro__(unquote(options))
    
      # Push details to Base, and read in required settings.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__poly__macro__(unquote(options))
    
    
      #----------------------
      # Derives
      #----------------------
      Module.register_attribute(__MODULE__, :__nzdo__derive, accumulate: true)
      @__nzdo__derive Noizu.ERP
      @__nzdo__derive Noizu.Entity.Protocol
      @__nzdo__derive Noizu.RestrictedAccess.Protocol
  
      #---------------------------------------------------------------------------------------------
      # Persistence
      #---------------------------------------------------------------------------------------------
      # Load Persistence Settings from base, we need them to control some submodules.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__persistence_settings__macro__(unquote(options))

      # Nmid
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__nmid__macro__(unquote(options))
  
      
      #---------------------------------------------------------------------------------------------
      # Index
      #---------------------------------------------------------------------------------------------
      # Load Sphinx Settings from base.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__sphinx__macro__(unquote(options))
  
  
      #---------------------------------------------------------------------------------------------
      # Json
      #---------------------------------------------------------------------------------------------
      # Json Settings
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__json_settings__macro__(unquote(options))
 

    end
  end

  def __implement__(options) do
    core_implementation = options[:core_implementation] || Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Default

    #---------------------------------------------------------------------------------------------
    # inspect
    #---------------------------------------------------------------------------------------------
    inspect_provider = cond do
                         options[:inspect_implementation] == false -> false
                         :else -> options[:inspect_implementation] || Noizu.AdvancedScaffolding.Internal.DomainObject.Inspect
                       end

    quote do
      alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
      @behaviour Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Behaviour
      
      
      
      #---------------------------------------------------------------------------------------------
      # core
      #---------------------------------------------------------------------------------------------
      require Logger
      @nzdo__core_implementation unquote(core_implementation)
      @__nzdo__implementation unquote(core_implementation)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sref_prefix__, do: "ref.#{@__nzdo__sref}."
    
      @doc """
          Retrieve Domain Object Version..
      """
      def vsn(), do: @__nzdo__base.vsn()
    
      @doc """
          Returns Entity struct (in this case the current module) for this DomainObject.Entity.
      """
      def __entity__(), do: __MODULE__
    
      @doc """
         Returns parent module. The base of User.Entity for example would be the User module.
      """
      def __base__(), do: @__nzdo__base
    
      @doc """
          Returns the Polymorphic base if multiple entities rely on the same DomainObject.Repo and related tables. Different CMS article types for example may all use the same
        generic repo and mnesia database table despite each having it's own unique struct defnition.
      """
      def __poly_base__(), do: @__nzdo__poly_base
      def __repo__(), do: @__nzdo__base.__repo__()
      def __sref__(), do: @__nzdo__base.__sref__()
      def __kind__(), do: @__nzdo__base.__kind__()
      def __erp__(), do: @__nzdo__base.__erp__()

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __valid_identifier__(identifier) do
        Noizu.DomainObject.IdentifierTypeResolver.__valid_identifier__(identifier, __noizu_info__(:identifier_type))
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sref_section_regex__(type) do
        Noizu.DomainObject.IdentifierTypeResolver.__sref_section_regex__(type)
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __id_to_string__(identifier) do
        Noizu.DomainObject.IdentifierTypeResolver.__id_to_string__(identifier, __noizu_info__(:identifier_type))
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __string_to_id__(identifier) do
        Noizu.DomainObject.IdentifierTypeResolver.__string_to_id__(identifier, __noizu_info__(:identifier_type))
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __valid__(%{__struct__: __MODULE__} = entity, context, options \\ nil), do: @__nzdo__implementation.__valid__(__MODULE__, entity, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @deprecated "Noizu.ERP.record is no longer used, V3 entities use __to_record__(table, entity, context, options) for casting to different persistence layers"
      def record(_ref, _options \\ nil), do: raise "Deprecated"
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @deprecated "Noizu.ERP.record! is no longer used, V3 entities use __to_record__(table, entity, context, options) for casting to different persistence layers"
      def record!(_ref, _options \\ nil), do: raise "Deprecated"

      cond do
        is_bitstring(@__nzdo__sref) ->
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def id("ref.#{@__nzdo__sref}" <> _ = v), do: id(ref(v))
          def id(ref), do: @__nzdo__implementation.id(__MODULE__, ref)
          # ref
          #-----------------
        
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def ref({:uuid_identifier, __MODULE__, <<uuid::binary-size(16)>>}), do: {:ref, __MODULE__, uuid}
          def ref({:uuid_identifier, __MODULE__, <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = uuid}), do: {:ref, __MODULE__, UUID.string_to_binary!(uuid)}
          def ref("ref.#{@__nzdo__sref}." <> id) do
            identifier = case __string_to_id__(id) do
                           {:ok, v} -> v
                           e = {:error, _} ->
                             Logger.info("[ref] #{inspect e}")
                             nil
                           v -> v
                         end
            identifier && {:ref, __MODULE__, identifier}
          end
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def ref("ref.#{@__nzdo__sref}" <> id) do
            identifier = case __string_to_id__(id) do
                           {:ok, v} -> v
                           e = {:error, _} ->
                             Logger.info("[ref] #{inspect e}")
                             nil
                           v -> v
                         end
            identifier && {:ref, __MODULE__, identifier}
          end
          def ref({:ecto_identifier, __MODULE__, identifier}), do: ref({:ref, __MODULE__, identifier})  # Oversimplification will need to be revisited if there is ID mapping.
          def ref(ref), do: @__nzdo__implementation.ref(__MODULE__, ref)
          # sref
          #-----------------
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def sref("ref.#{@__nzdo__sref}" <> _ = ref), do: ref
          def sref(ref), do: @__nzdo__implementation.sref(__MODULE__, ref)
          # entity
          #-----------------
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def entity("ref.#{@__nzdo__sref}" <> _ = v), do: entity(ref(v))
          def entity(ref, options \\ nil), do: @__nzdo__implementation.entity(__MODULE__, ref, options)
          # entity!
          #-----------------
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def entity!("ref.#{@__nzdo__sref}" <> _ = v), do: entity!(ref(v))
          def entity!(ref, options \\ nil), do: @__nzdo__implementation.entity!(__MODULE__, ref, options)
      
      
      
        :else ->
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def id(ref), do: @__nzdo__implementation.id(__MODULE__, ref)
          # ref
          #-----------------
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def ref({:ecto_identifier, __MODULE__, identifier}), do: ref({:ref, __MODULE__, identifier})  # Oversimplification will need to be revisited if there is ID mapping.
          def ref(ref), do: @__nzdo__implementation.ref(__MODULE__, ref)
          # sref
          #-----------------
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def sref(ref), do: @__nzdo__implementation.sref(__MODULE__, ref)
          # entity
          #-----------------
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def entity(ref, options \\ nil), do: @__nzdo__implementation.entity(__MODULE__, ref, options)
          # entity!
          #-----------------
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def entity!(ref, options \\ nil), do: @__nzdo__implementation.entity!(__MODULE__, ref, options)
    
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def id_ok(o) do
        r = id(o)
        r && {:ok, r} || {:error, o}
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      if is_bitstring(@__nzdo__sref) do
        def ref_ok("ref.#{@__nzdo__sref}." <> id) do
          identifier = case __string_to_id__(id) do
                         {:ok, v} -> v && {:ok, {:ref, __MODULE__, v}}
                         e = {:error, _} -> e
                         v -> v && {:ok, {:ref, __MODULE__, v}}
                       end
        end
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def ref_ok("ref.#{@__nzdo__sref}" <> id) do
          identifier = case __string_to_id__(id) do
                         {:ok, v} -> v && {:ok, {:ref, __MODULE__, v}}
                         e = {:error, _} -> e
                         v -> v && {:ok, {:ref, __MODULE__, v}}
                       end
        end
      end
      def ref_ok(ref) do
        @__nzdo__implementation.ref_ok(__MODULE__, ref)
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def sref_ok(ref) do
        @__nzdo__implementation.sref_ok(__MODULE__, ref)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def entity_ok(o, options \\ %{}) do
        r = entity(o, options)
        r && {:ok, r} || {:error, o}
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def entity_ok!(o, options \\ %{}) do
        r = entity!(o, options)
        r && {:ok, r} || {:error, o}
      end
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def has_permission?(ref, permission, context, options \\ []), do: @__nzdo__implementation.has_permission?(__MODULE__, ref, permission, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def has_permission!(ref, permission, context, options \\ []), do: @__nzdo__implementation.has_permission!(__MODULE__, ref, permission, context, options)
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def version_change(_vsn, entity, _context, _options \\ nil), do: entity
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def version_change!(_vsn, entity, _context, _options \\ nil), do: entity
    
      defoverridable [
        __sref_prefix__: 0,
      
        vsn: 0,
        __entity__: 0,
        __base__: 0,
        __poly_base__: 0,
        __repo__: 0,
        __sref__: 0,
        __kind__: 0,
        __erp__: 0,
      
        __valid_identifier__: 1,
        __sref_section_regex__: 1,
        __id_to_string__: 1,
        __string_to_id__: 1,
      
      
        __valid__: 2,
        __valid__: 3,
      
        id: 1,
        ref: 1,
        sref: 1,
        entity: 1,
        entity: 2,
        entity!: 1,
        entity!: 2,
      
        id_ok: 1,
        ref_ok: 1,
        sref_ok: 1,
        entity_ok: 1,
        entity_ok: 2,
        entity_ok!: 1,
        entity_ok!: 2,
      
        record: 1,
        record: 2,
        record!: 1,
        record!: 2,
      
        has_permission?: 3,
        has_permission?: 4,
        has_permission!: 3,
        has_permission!: 4,
        version_change: 3,
        version_change: 4,
        version_change!: 3,
        version_change!: 4,
      ]

      #---------------------------------------------------------------------------------------------
      # Persistence
      #---------------------------------------------------------------------------------------------
      @nzdo__persistence_implementation unquote(core_implementation)

      def __to_cache__!(ref, _context, _options) do
        Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Default.strip_transient(ref)
      end
      def __from_cache__!(ref, _context, _options) do
        ref
      end

      #=======================================
      # Persistence
      #=======================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __as_record__(%{__struct__: PersistenceLayer} = layer, entity, context, options \\ nil), do: @nzdo__persistence_implementation.__as_record__(__MODULE__, layer, entity, context, options)
      def __as_record__!(%{__struct__: PersistenceLayer} = layer, entity, context, options \\ nil), do: @nzdo__persistence_implementation.__as_record__!(__MODULE__, layer, entity, context, options)


      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __as_record_type__(%{__struct__: PersistenceLayer} = layer, entity, context, options \\ nil),
          do: @nzdo__persistence_implementation.__as_record_type__(__MODULE__, layer, entity, context, options)
      def __as_record_type__!(%{__struct__: PersistenceLayer} = layer, entity, context, options \\ nil),
          do: @nzdo__persistence_implementation.__as_record_type__!(__MODULE__, layer, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __from_record__(%{__struct__: PersistenceLayer} = layer, record, context, options \\ nil), do: @nzdo__persistence_implementation.__from_record__(__MODULE__, layer, record, context, options)
      def __from_record__!(%{__struct__: PersistenceLayer} = layer, record, context, options \\ nil), do: @nzdo__persistence_implementation.__from_record__!(__MODULE__, layer, record, context, options)


      if (@__nzdo_persistence.ecto_entity) do
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def ecto_entity?(), do: true
  
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def ecto_identifier({:ecto_identifier, __MODULE__, v}), do: v
        cond do
          Module.has_attribute?(__MODULE__, :__nzdo__ecto_identifier_field) -> def ecto_identifier(ref), do: @nzdo__persistence_implementation.ecto_identifier(__MODULE__, ref)
          Module.get_attribute(__MODULE__, :__nzdo__identifier_type) == :integer -> def ecto_identifier(ref), do: id(ref)
          Module.get_attribute(__MODULE__, :__nzdo__identifier_type) == :uuid ->
            def ecto_identifier(ref) do
              case id(ref) do
                nil -> nil
                <<v::binary-size(16)>> -> UUID.binary_to_string!(v)
                v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> -> v
                v -> v
              end
            end
          Module.get_attribute(__MODULE__, :__nzdo__identifier_type) ->
            def ecto_identifier(ref) do
              cond do
                function_exported?(@__nzdo__identifier_type, :__ecto_identifier__, 1) ->
                  case @__nzdo__identifier_type do
                    {:ok, v} -> v
                    error -> raise "ecto_identifier error #{inspect error}"
                  end
                :else -> raise "Not Supported"
              end
            end
          :else -> def ecto_identifier(_), do: raise "Not Supported"
        end
  
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def source(_), do: @__nzdo_persistence.ecto_entity
  
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        cond do
          @__nzdo_persistence.options[:universal_identifier] -> def universal_identifier(ref) do
                                                                  case __noizu_info__(:identifier_type) do
                                                                    :uuid ->
                                                                      case id(ref) do
                                                                        <<v::binary-size(16)>> -> UUID.binary_to_string!(v)
                                                                        v -> v
                                                                      end
                                                                    _ -> id(ref)
                                                                  end
                                                                end
          @__nzdo_persistence.options[:universal_lookup] -> def universal_identifier(ref), do: @nzdo__persistence_implementation.universal_identifier_lookup(__MODULE__, ref)
          :else -> def universal_identifier(_), do: raise "Not Supported"
        end
        def index_identifier(ref), do: id(ref)
      else
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def ecto_entity?(), do: false
        def ecto_identifier(_), do: nil
        def source(_), do: nil
        def universal_identifier(_), do: nil
        def index_identifier(_), do: nil
      end
      
      defoverridable [
        ecto_entity?: 0,
        ecto_identifier: 1,
        universal_identifier: 1,
        source: 1,
  
        __as_record__: 3,
        __as_record__: 4,
        __as_record__!: 3,
        __as_record__!: 4,
  
        __as_record_type__: 3,
        __as_record_type__: 4,
  
        __as_record_type__!: 3,
        __as_record_type__!: 4,
  
        __from_record__: 3,
        __from_record__: 4,
        __from_record__!: 3,
        __from_record__!: 4,
  
  
        __from_cache__!: 3,
        __to_cache__!: 3,
      ]

      #---------------------------------------------------------------------------------------------
      # Index
      #---------------------------------------------------------------------------------------------
      @__nzdo__entity_index_implementation unquote(core_implementation)

      #------------------------------
      #
      #------------------------------
      def __write_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__entity_index_implementation.__write_index__(__MODULE__, entity, index, settings, context, options)

      def __update_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__entity_index_implementation.__update_index__(__MODULE__, entity, index, settings, context, options)

      def __delete_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__entity_index_implementation.__delete_index__(__MODULE__, entity, index, settings, context, options)

      #------------------------------
      #
      #------------------------------
      def __write_indexes__(entity, context, options \\ nil) do
        Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __write_index__(entity, index, settings, context, options) end)
        entity
      end

      def __update_indexes__(entity, context, options \\ nil) do
        Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __update_index__(entity, index, settings, context, options) end)
        entity
      end

      def __delete_indexes__(entity, context, options \\ nil) do
        Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __delete_index__(entity, index, settings, context, options) end)
        entity
      end

      defoverridable [
        __write_index__: 4,
        __write_index__: 5,
  
        __update_index__: 4,
        __update_index__: 5,
  
        __delete_index__: 4,
        __delete_index__: 5,
  
        __write_indexes__: 2,
        __write_indexes__: 3,
  
        __update_indexes__: 2,
        __update_indexes__: 3,
  
        __delete_indexes__: 2,
        __delete_indexes__: 3,
      ]

      #---------------------------------------------------------------------------------------------
      # Json
      #---------------------------------------------------------------------------------------------
      @__nzdo__json_implementation unquote(core_implementation)

      #---------------
      # Poison
      #---------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      if (__nzdo__json_provider = @__nzdo__json_provider) do
        defimpl Poison.Encoder  do
          @__nzdo__json_provider __nzdo__json_provider
          def encode(entity, options \\ nil), do: @__nzdo__json_provider.encode(entity, options)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __strip_pii__(entity, level), do: @__nzdo__json_implementation.__strip_pii__(__MODULE__, entity, level)


      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Parse Json to obtain entity of this type.

      @note this should probably be a repo method although with polymorphism that gets a little complex, will be moved later.
      """
      def from_json(format, json, context, options \\ nil), do: @__nzdo__json_implementation.from_json(__MODULE__, format, json, context, options)

      defoverridable [
        __strip_pii__: 2,
        from_json: 3,
        from_json: 4,
      ]
      
      #---------------------------------------------------------------------------------------------
      # Inspect
      #---------------------------------------------------------------------------------------------
      @__nzdo__inspect_implementation unquote(core_implementation)
      
      #---------------
      # Inspect - @TODO use derive mechanism here not direct defimpl
      #---------------
      def __inspect_provider__(), do: unquote(inspect_provider)
      

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __strip_inspect__(entity, opts), do: @__nzdo__inspect_implementation.__strip_inspect__(__MODULE__, entity, opts)

      defoverridable [
        __strip_inspect__: 2,
      ]
    end
  end


  defmacro __before_compile__(_env) do
    quote do
      #---------------------------------------------------------------------------------------------
      # core
      #---------------------------------------------------------------------------------------------
      
      if options = Module.get_attribute(@__nzdo__base, :enum_list) do
        Module.put_attribute(@__nzdo__base, :__nzdo_enum_field, options)
      end
    
    
      # this belongs in the json handler our json endpoint should forward to that method. __json__(:config)
      @__nzdo__json_config put_in(@__nzdo__json_config, [:format_settings], @__nzdo__raw__json_format_settings)
    
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__field_attributes_map Enum.reduce(@__nzdo__field_attributes, %{}, fn({field, options}, acc) ->
        options = case options do
                    %{} -> options
                    v when is_list(v) -> Map.new(v)
                    v when is_atom(v) -> Map.new([{v, true}])
                    v when is_tuple(v) -> Map.new([{v, true}])
                    nil -> %{}
                  end
        update_in(acc, [field], &( Map.merge(&1 || %{}, options)))
      end)
    
      @__nzdo__persisted_fields Enum.filter(@__nzdo__field_list -- [:__initial__, :__transient__], &(!@__nzdo__field_attributes_map[&1][:transient]))
      @__nzdo__transient_fields Enum.filter(@__nzdo__field_list, &(@__nzdo__field_attributes_map[&1][:transient])) ++ [:__initial__, :__transient__]
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo_associated_types (
                                 Enum.map(@__nzdo_persistence__by_table || %{}, fn ({k, v}) -> {k, v.type} end) ++ Enum.map(
                                   @__nzdo__poly_support || [],
                                   fn (k) -> {Module.concat([k, "Entity"]), :poly} end
                                 ))
                               |> Map.new()
    
    
    
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__field_permissions_map Enum.reduce(@__nzdo__field_permissions, %{}, fn({field, options}, acc) ->
        options = case options do
                    %{} -> options
                    v when is_list(v) -> Map.new(v)
                    v when is_atom(v) -> Map.new([{v, true}])
                    v when is_tuple(v) -> Map.new([{v, true}])
                    nil -> %{}
                  end
        update_in(acc, [field], &( Map.merge(&1 || %{}, options)))
      end)
    
      #################################################
      # __noizu_info__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        Domain Object Configuration Details
      """
      def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :entity)
      @doc """
        Domain Object Configuration Details
      """
      def __noizu_info__(:type), do: :entity
      def __noizu_info__(:identifier_type), do: @__nzdo__identifier_type
      def __noizu_info__(:fields), do: @__nzdo__field_list
      def __noizu_info__(:persisted_fields), do: @__nzdo__persisted_fields
      def __noizu_info__(:field_types), do: @__nzdo__field_types_map
      def __noizu_info__(:persistence), do: __persistence__()
      def __noizu_info__(:associated_types), do: @__nzdo_associated_types
      def __noizu_info__(:json_configuration), do: @__nzdo__json_config
      def __noizu_info__(:field_attributes), do: @__nzdo__field_attributes_map
      def __noizu_info__(:field_permissions), do: @__nzdo__field_permissions_map
      def __noizu_info__(:indexing), do: __indexing__()
      def __noizu_info__(report), do: @__nzdo__base.__noizu_info__(report)
    
      #################################################
      # __fields__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        Domain Object Field Configuration
      """
      def __fields__() do
        Enum.map([:fields, :persisted, :types, :json, :attributes, :permissions], &({&1,__fields__(&1)}))
      end
      @doc """
        Domain Object Field Configuration
      """
      def __fields__(:fields), do: @__nzdo__field_list
      def __fields__(:persisted), do: @__nzdo__persisted_fields
      def __fields__(:transient), do: @__nzdo__transient_fields
      def __fields__(:types), do: @__nzdo__field_types_map
      def __fields__(:json), do: @__nzdo__json_config
      def __fields__(:attributes), do: @__nzdo__field_attributes_map
      def __fields__(:permissions), do: @__nzdo__field_permissions_map
    
      #################################################
      # __enum__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        Domain Object Enum Settings for Enum/Lookup.Table entities.
      """
      def __enum__(), do: @__nzdo__base.__enum__()
      @doc """
        Domain Object Enum Settings for Enum/Lookup.Table entities.
      """
      def __enum__(property), do: @__nzdo__base.__enum__(property)
    
      defoverridable [
        __noizu_info__: 0,
        __noizu_info__: 1,
        __fields__: 0,
        __fields__: 1,
        __enum__: 0,
        __enum__: 1,
      ]
  
  
      #---------------------------------------------------------------------------------------------
      # Persistence
      #---------------------------------------------------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      if (@__nzdo_persistence.ecto_entity) do
        if v = @__nzdo_persistence.options[:generate_reference_type] do
          cond do
            v == :enum_ref ->
              Module.put_attribute(@__nzdo__base, :__nzdo_enum_ref, true)
            v == :basic_ref ->
              Module.put_attribute(@__nzdo__base, :__nzdo_basic_ref, true)
            v == :universal_ref ->
              Module.put_attribute(@__nzdo__base, :__nzdo_universal_ref, true)
            @__nzdo_persistence.options[:universal_reference] == false && @__nzdo_persistence.options[:enum_table] ->
              Module.put_attribute(@__nzdo__base, :__nzdo_enum_ref, true)
            @__nzdo_persistence.options[:universal_reference] || @__nzdo_persistence.options[:universal_lookup] ->
              Module.put_attribute(@__nzdo__base, :__nzdo_universal_ref, true)
            :else ->
              Module.put_attribute(@__nzdo__base, :__nzdo_basic_ref, true)
          end
        end
      end




      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo_persistence Noizu.AdvancedScaffolding.Schema.PersistenceSettings.update_schema_fields(@__nzdo_persistence, @__nzdo__field_types_map)
      if @__nzdo__base_open? do
        Module.put_attribute(@__nzdo__base, :__nzdo_persistence, @__nzdo_persistence)
      end



      #################################################
      # __persistence__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
         Entity persistence settings (various databases read or written to when updating/fetching a domain object entity.)"
      """
      def __persistence__(), do: __persistence__(:all)
      @doc """
         Entity persistence settings (various databases read or written to when updating/fetching a domain object entity.)"
      """
      def __persistence__(:all) do
        [:telemetry, :enum_table, :auto_generate, :universal_identifier, :universal_lookup, :reference_type, :layers, :schemas, :tables, :ecto_entity, :options]
        |> Enum.map(&({&1, __persistence__(&1)}))
        |> Map.new()
      end
      def __persistence__(:telemetry), do: @__nzdo__telemetry
      def __persistence__(:ecto_type), do: @__nzdo__enum_ecto_type
      def __persistence__(:enum_table), do: @__nzdo_persistence.options.enum_table
      def __persistence__(:auto_generate), do: @__nzdo_persistence.options.auto_generate
      def __persistence__(:universal_identifier), do: @__nzdo_persistence.options.universal_identifier
      def __persistence__(:universal_lookup), do: @__nzdo_persistence.options.universal_lookup
      def __persistence__(:reference_type), do: @__nzdo_persistence.options.generate_reference_type
      def __persistence__(:layers), do: @__nzdo_persistence.layers
      def __persistence__(:schemas), do: @__nzdo_persistence.schemas
      def __persistence__(:tables), do: @__nzdo_persistence.tables
      def __persistence__(:ecto_entity), do: @__nzdo_persistence.ecto_entity
      def __persistence__(:options), do: @__nzdo_persistence.options
      def __persistence__(repo, :table), do: @__nzdo_persistence.schemas[repo] && @__nzdo_persistence.schemas[repo].table

      #################################################
      # __nmid__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        Unique Identifier Generator Config Settings .
      """
      def __nmid__(), do: __nmid__(:all)
      @doc """
        Unique Identifier Generator Config Settings .
      """
      def __nmid__(:all) do
        %{
          generator: __nmid__(:generator),
          sequencer: __nmid__(:sequencer),
          bare: __nmid__(:bare),
          index: __nmid__(:index),
        }
      end
      if @__nzdo__nmid_index do
        def __nmid__(:index) do
          @__nzdo__nmid_index
        end
      else
        def __nmid__(:index) do
          cond do
            !@__nzdo__schema_helper ->
              {f,a} = __ENV__.function
              raise """
              #{__MODULE__}.#{f}/#{a}:#{unquote(__ENV__.line)}@#{__MODULE__} - nmid_index required to generate node/entity unique identifiers.
              You must pass in noizu_domain_object_schema to the Entity, set the noizu_scaffolding: DomainObjectSchema config option (@see Noizu.AdvancedScaffolding.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider.Default)
              Or specify a one off for this specific table by adding @nmid_index annotation or [nmid_index: value] to the DomainObject.noizu_entity or derived macro.
              """
            v = Kernel.function_exported?(@__nzdo__schema_helper, :__noizu_info__, 1) && apply(@__nzdo__schema_helper, :__noizu_info__, [:nmid_indexes])[__MODULE__] -> v
            v = Kernel.function_exported?(@__nzdo__schema_helper, :__noizu_info__, 1) && apply(@__nzdo__schema_helper, :__noizu_info__, [:nmid_indexes]) ->
              {f,a} = __ENV__.function
              raise """
              #{__MODULE__}.#{f}/#{a}:#{unquote(__ENV__.line)}@#{__MODULE__} - schema helper has no nmid_index entry for #{__MODULE__}}.
              Update schema helper (#{@__nzdo__schema_helper}) or provide a one off declaration @nmid_index 123.
              """
            :else ->
              {f,a} = __ENV__.function
              raise """
              #{__MODULE__}.#{f}/#{a}:#{unquote(__ENV__.line)}@#{__MODULE__} - nmid_index not supported by schema helper.
              Update schema helper (#{@__nzdo__schema_helper}) or provide a one off declaration @nmid_index 123.
              """
          end
        end
      end
      def __nmid__(setting), do: @__nzdo__base.__nmid__(setting)
  
      #---------------------------------------------------------------------------------------------
      # Index
      #---------------------------------------------------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__indexes Enum.reduce(
                         List.flatten(@__nzdo__field_indexing || []),
                         @__nzdo__indexes,
                         fn ({{field, index}, indexing}, acc) ->
                           index_field_config = cond do
                                                  existing = acc[index][:fields][field] ->
                                                    Enum.reduce(indexing, existing, fn ({k, v}, acc) ->
                                                      put_in(acc, [k], v)
                                                    end)
                                                  :else -> indexing
                                                end
                           index_field_config = cond do
                                                  index_field_config[:with] -> index_field_config
                                                  index_field_config[:with] == false -> index_field_config
                                                  ft = Module.get_attribute(__MODULE__, :__nzdo__field_types_map, [])[field] ->
                                                    put_in(index_field_config, [:with], ft.handler)
                                                  :else -> index_field_config
                                                end
                           acc && put_in(acc, [index, :fields, field], index_field_config)
                         end
                       )


      #################################################
      # __indexing__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        Search Index Configuration
      """
      def __indexing__(), do: @__nzdo__indexes

      @doc """
        Search Index Configuration
      """
      def __indexing__(p), do: @__nzdo__indexes[p]
      
      #---------------------------------------------------------------------------------------------
      # Json
      #---------------------------------------------------------------------------------------------

      #################################################
      # __json__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        Json Encoding/Decoding settings.
      """
      def __json__(), do: @__nzdo__base.__json__()
      def __json__(property), do: @__nzdo__base.__json__(property)
      
    end
  end


  def __after_compile__(env, _bytecode) do
    # Validate Generated Object
    if p = env.module.__inspect_provider__() do
      quote do
        defimpl Inspect do
          def inspect(entity, opts), do: unquote(p).inspect(entity, opts)
        end
      end
    end
  end
  
  
  
  
  
end
