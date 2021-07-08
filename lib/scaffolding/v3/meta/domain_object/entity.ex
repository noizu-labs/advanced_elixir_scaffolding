#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity do
  alias Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity, as: EntityMeta



  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __before_compile__(_) do
    macro_file = __ENV__.file
    quote do
      defdelegate vsn(), to: @__nzdo__base
      def __entity__(), do: __MODULE__
      def __base__(), do: @__nzdo__base
      defdelegate __enum_type__(), to: @__nzdo__base
      defdelegate __repo__(), to: @__nzdo__base
      defdelegate __sref__(), to: @__nzdo__base
      defdelegate __erp__(), to: @__nzdo__base



      @file unquote(macro_file) <> "<associated_type>"
      @__nzdo_associated_types (
                                 Enum.map(@__nzdo_persistence__by_table || %{}, fn ({k, v}) -> {k, v.type} end) ++ Enum.map(
                                   @__nzdo__poly_support || %{},
                                   fn (k) -> {k, :poly} end
                                 ))
                               |> Map.new()
      @__nzdo__json_config put_in(@__nzdo__json_config, [:format_settings], @__nzdo__raw__json_format_settings)
      @__nzdo__field_attributes_map Map.new(@__nzdo__field_attributes)

      @__nzdo_persistence Noizu.Scaffolding.V3.Schema.PersistenceSettings.update_schema_fields(@__nzdo_persistence, @__nzdo__field_types_map)
      if @__nzdo__base_open? do
        Module.put_attribute(@__nzdo__base, :__nzdo_persistence, @__nzdo_persistence)
      end

      @__nzdo__indexes Enum.reduce(
                         List.flatten(@__nzdo__field_indexing || []),
                         @__nzdo__indexes,
                         fn ({{field, index}, indexing}, acc) ->
                           cond do
                             acc[index][:fields][field] == nil ->
                               put_in(acc, [index, :fields, field], indexing)
                             e = acc[index][:fields][field] ->
                               e = Enum.reduce(indexing, e, fn ({k, v}, acc) -> put_in(acc, [k], v) end)
                               put_in(acc, [index, :fields, field], e)
                           end
                         end
                       )

      def __indexing__(), do: __indexing__(:indexes)
      def __indexing__(:indexes), do: @__nzdo__indexes

      def __persistence__(), do: __persistence__(:all)
      def __persistence__(:all) do
        [:enum_table, :auto_generate, :universal_identifier, :universal_lookup, :reference_type, :layers, :schemas, :tables, :ecto_entity, :options]
        |> Enum.map(&({&1, __persistence__(&1)}))
        |> Map.new()
      end
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

      def __nmid__(), do: __nmid__(:all)
      def __nmid__(:all) do
        %{
          generator: __nmid__(:generator),
          sequencer: __nmid__(:sequencer),
          bare: __nmid__(:bare),
          index: __nmid__(:index),
        }
      end
      def __nmid__(:index), do: @__nzdo__nmid_index || @__nzdo__schema_helper.__noizu_info__(:nmid_indexes)[__MODULE__]
      defdelegate __nmid__(setting), to: @__nzdo__base


      def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :entity)
      def __noizu_info__(:type), do: :entity
      def __noizu_info__(:identifier_type), do: @__nzdo__identifier_type
      def __noizu_info__(:fields), do: @__nzdo__field_list
      def __noizu_info__(:field_types), do: @__nzdo__field_types_map
      def __noizu_info__(:persistence), do: __persistence__()
      def __noizu_info__(:associated_types), do: @__nzdo_associated_types
      def __noizu_info__(:json_configuration), do: @__nzdo__json_config
      def __noizu_info__(:field_attributes), do: @__nzdo__field_attributes_map
      def __noizu_info__(:indexing), do: __indexing__()
      defdelegate __noizu_info__(report), to: @__nzdo__base


      # only defined for enum types.
      if @__nzdo_persistence.options.enum_table do
        def __enum__(), do: __noizu_info__(:enum)
      end



    end
  end


  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_entity__(caller, options, block) do
    erp_provider = options[:erp_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider
    index_provider = options[:index_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultIndexProvider
    internal_provider = options[:internal_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider
    persistence_provider = options[:persistence_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultPersistenceProvider
    macro_file = __ENV__.file
    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]
                       require Noizu.DomainObject
                       require Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                       import Noizu.ElixirCore.Guards
                       @options unquote(options)
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(macro_file) <> "<single_call>"
                       if line = Module.get_attribute(__MODULE__, :__nzdo__entity_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_entity first defined on #{elem(line, 0)}:#{
                           elem(line, 1)
                         }"
                       end
                       @__nzdo__entity_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       # Extract Base Fields fields since SimbpleObjects are at the same level as their base.
                       @file unquote(macro_file) <> "<__prepare__base__macro__>"
                       Noizu.DomainObject.__prepare__base__macro__(@options)

                       # Push details to Base, and read in required settings.
                       @file unquote(macro_file) <> "<__prepare__poly__macro__>"
                       Noizu.DomainObject.__prepare__poly__macro__(@options)

                       # Load Sphinx Settings from base.
                       @file unquote(macro_file) <> "<__prepare__sphinx__macro__>"
                       Noizu.DomainObject.__prepare__sphinx__macro__(@options)

                       # Load Persistence Settings from base, we need them to control some submodules.
                       @file unquote(macro_file) <> "<__prepare__persistence_settings__macro__>"
                       Noizu.DomainObject.__prepare__persistence_settings__macro__(@options)

                       # Nmid
                       @file unquote(macro_file) <> "<__prepare__nmid__macro__>"
                       Noizu.DomainObject.__prepare__nmid__macro__(@options)

                       # Json Settings
                       @file unquote(macro_file) <> "<__prepare__json_settings__macro__>"
                       Noizu.DomainObject.__prepare__json_settings__macro__(@options)

                       #----------------------
                       # Derives
                       #----------------------
                       @__nzdo__derive Noizu.ERP
                       @__nzdo__derive Noizu.V3.EntityProtocol
                       @__nzdo__derive Noizu.V3.RestrictedProtocol

                       # Prep attributes for loading individual fields.
                       @file unquote(macro_file) <> "<__register__field_attributes__macro__>"
                       Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__register__field_attributes__macro__(@options)

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         # we rely on the same providers as used in the Entity type for providing json encoding, restrictions, etc.
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                         @file unquote(macro_file) <> "<block>"
                         unquote(block)
                       after
                         :ok
                       end

                       @file unquote(macro_file) <> "<__post_struct_definition_macro__>"
                       Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__post_struct_definition_macro__(@options)

                       :ok
                     end

    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields
               end

    quote do


      @file unquote(macro_file) <> "<process_config>"
      unquote(process_config)
      @file unquote(macro_file) <> "<generate>"
      unquote(generate)


      #---------------
      # Poison
      #---------------
      if (@__nzdo__json_provider) do
        __nzdo__json_provider = @__nzdo__json_provider
        defimpl Poison.Encoder  do
          defdelegate encode(entity, options \\ nil), to: __nzdo__json_provider
        end
      end

      #---------------
      # Inspect
      #---------------
      defimpl Inspect do
        defdelegate inspect(entity, opts), to: Noizu.ElixirScaffolding.V3.Meta.DomainObject.Inspect
      end

      @file unquote(macro_file) <> "<erp_provider>"
      use unquote(erp_provider)
      @file unquote(macro_file) <> "<index_provider>"
      use unquote(index_provider)
      @file unquote(macro_file) <> "<persistence_provider>"
      use unquote(persistence_provider)
      @file unquote(macro_file) <> "<internal_provider>"
      use unquote(internal_provider)
      @before_compile unquote(internal_provider)
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
      @after_compile unquote(internal_provider)
    end
  end




  #--------------------------
  #
  #--------------------------
  defmacro identifier(type \\ :integer, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, :identifier, unquote(opts))
      EntityMeta.__identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  def __identifier__(mod, type, _opts) do
    Module.put_attribute(mod, :__nzdo__identifier_type, type)
    __public_field__(mod, :identifier, nil, [])
  end


  #--------------------------
  #
  #--------------------------
  defmacro ecto_identifier(type \\ :integer, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, :ecto_identifier, unquote(opts))
      EntityMeta.__ecto_identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  def __ecto_identifier__(mod, _type, _opts) do
    Module.put_attribute(mod, :__nzdo__ecto_identifier_field, true)
    __public_field__(mod, :ecto_identifier, nil, [])
  end

  #--------------------------
  #
  #--------------------------
  defmacro public_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__public_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __public_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :public})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro public_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__public_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __public_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __public_field__(mod, field, default, opts)
      end
    )
  end

  #--------------------------
  #
  #--------------------------
  defmacro restricted_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__restricted_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __restricted_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :restricted})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro restricted_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__restricted_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __restricted_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __restricted_field__(mod, field, default, opts)
      end
    )
  end

  #--------------------------
  #
  #--------------------------
  defmacro private_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__private_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __private_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :private})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro private_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__private_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __private_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __private_field__(mod, field, default, opts)
      end
    )
  end

  #--------------------------
  #
  #--------------------------
  defmacro internal_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__internal_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __internal_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :internal})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro internal_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__internal_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __internal_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __internal_field__(mod, field, default, opts)
      end
    )
  end

  #--------------------------
  #
  #--------------------------
  def pii_level(value) do
    levels = %{
      0 => :level_0,
      1 => :level_1,
      2 => :level_2,
      3 => :level_3,
      4 => :level_4,
      5 => :level_5,
      6 => :level_6,
      :level_0 => :level_0,
      :level_1 => :level_1,
      :level_2 => :level_2,
      :level_3 => :level_3,
      :level_4 => :level_4,
      :level_5 => :level_5,
      :level_6 => :level_6,

      true => :level_3,
      false => :level_6,
      :default => :level_6,
    }
    levels[value] || levels[:default]
  end



  def __field_attribute_normalize__(:pii, attr_value), do: EntityMeta.pii_level(attr_value)
  def __field_attribute_normalize__(:required, attr_value) do
    case attr_value do
      [ref: v] -> {:ref, __field_attribute_normalize__(:ref, v)}
      [enum: v] -> {:enum, __field_attribute_normalize__(:enum, v)}
      [struct: v] -> {:struct, __field_attribute_normalize__(:struct, v)}
      {:ref, v} -> {:ref, __field_attribute_normalize__(:ref, v)}
      {:enum, v} -> {:enum, __field_attribute_normalize__(:enum, v)}
      {:struct, v} -> {:struct, __field_attribute_normalize__(:struct, v)}
      _else -> attr_value
    end
  end
  def __field_attribute_normalize__(:enum, attr_value) do
    case attr_value do
      true -> :any
      v when is_list(v) -> List.flatten(v)
      v when is_atom(v) -> v
    end
  end
  def __field_attribute_normalize__(type, attr_value) when type == :ref or type == :struct do
    case attr_value do
      true -> :any
      v when is_list(v) -> MapSet.new(List.flatten(v))
      v when is_atom(v) -> MapSet.new([v])
    end
  end



  def __field_attribute_valid__?(:pii, attr_value) do

    cond do
      is_integer(attr_value) && attr_value >= 0 && attr_value <= 6 -> true
      Enum.member?([:level_0, :level_1, :level_2, :level_3, :level_4, :level_5, :level_6], attr_value) -> true
      attr_value == nil -> :ignore
      attr_value == [] -> :ignore
      :else -> false
    end
  end

  def __field_attribute_valid__?(:required, attr_value) do
    case attr_value do
      nil -> :ignore
      true -> true
      false -> true
      {_m, _f} -> true
      {_m, _f, _a} -> true
      f when is_function(f, 1) -> true
      f when is_function(f, 2) -> true
      f when is_function(f, 3) -> true
      f when is_function(f, 4) -> true
      [ref: v] -> __field_attribute_valid__?(:ref, v) && :ref
      [enum: v] -> __field_attribute_valid__?(:enum, v) && :enum
      [struct: v] -> __field_attribute_valid__?(:struct, v) && :struct
      {:ref, v} -> __field_attribute_valid__?(:ref, v) && :ref
      {:enum, v} -> __field_attribute_valid__?(:enum, v) && :enum
      {:struct, v} -> __field_attribute_valid__?(:struct, v) && :struct
      _else -> false
    end
  end
  def __field_attribute_valid__?(type, attr_value) when type == :ref or type == :struct or type == :enum do
    case attr_value do
      nil -> :ignore
      [] -> :ignore
      v when is_list(v) -> true
      v when is_atom(v) -> true
      true -> true
      _ -> false
    end
  end

  def __set_field_attributes__(mod, field, opts) do
    cond do
      nil == opts -> :ok
      [] == opts -> :ok
      is_atom(opts) -> Module.put_attribute(mod, :__nzdo__field_types, {field, %{handler: opts}})
      (is_list(opts) || is_map(opts)) && opts[:type] ->
        Module.put_attribute(mod, :__nzdo__field_types, {field, %{handler: opts[:type]}})
      :else -> :ok
    end

    EntityMeta.__set_json_settings__(mod, field, opts)
    EntityMeta.__set_index_settings__(mod, field, opts)
    EntityMeta.__set_permission_settings__(mod, field, opts)

    options = Enum.map(
                [:pii, :ref, :enum, :struct, :required],
                fn (attribute) ->
                  cond do
                    Module.has_attribute?(mod, attribute) ->
                      attr_value = Module.get_attribute(mod, attribute)
                      Module.delete_attribute(mod, attribute)
                      valid? = EntityMeta.__field_attribute_valid__?(attribute, attr_value)
                      valid? || raise "#{mod}.#{field} unsupported @#{attribute} value #{inspect attr_value}}"
                      attr_value = EntityMeta.__field_attribute_normalize__(attribute, attr_value)

                      cond do
                        valid? == :ignore -> nil
                        :else ->
                          case attribute do
                            :pii -> {:pii, attr_value}
                            :ref -> {:type_constraint, {:ref, attr_value}}
                            :struct -> {:type_constraint, {:struct, attr_value}}
                            :enum ->
                              case attr_value do
                                :any -> {:type_constraint, {:atom, :any}}
                                v when is_list(v) -> {:type_constraint, {:atom, MapSet.new(v)}}
                                v -> {:type_constraint, {:enum, v}}
                              end
                            :required ->
                              case attr_value do
                                {:ref, v} ->
                                  [{:required, true}, {:type_constraint, {:ref, v}}]
                                {:struct, v} ->
                                  [{:required, true}, {:type_constraint, {:struct, v}}]
                                {:enum, v} ->
                                  type_constraint = case v do
                                                      :any -> {:type_constraint, {:atom, :any}}
                                                      v when is_list(v) -> {:type_constraint, {:atom, MapSet.new(v)}}
                                                      _else -> {:type_constraint, {:enum, v}}
                                                    end
                                  [{:required, true}, type_constraint]
                                _ ->
                                  {:required, attr_value}
                              end
                          end
                      end


                    :else -> nil
                  end
                end
              )
              |> Enum.filter(&(&1))
              |> List.flatten()

    if options != [] do
      Module.put_attribute(mod, :__nzdo__field_attributes, {field, Map.new(options)})
    end
  end


  #---------------------------------
  #
  #---------------------------------
  def __set_index_settings__(mod, field, opts) do
    indexers = Module.get_attribute(mod, :__nzdo__index_list)
    entries = Module.get_attribute(mod, :index)
    Module.delete_attribute(mod, :index)
    o = EntityMeta.__extract_index_settings__(mod, field, indexers, entries, opts)
    o && Module.put_attribute(mod, :__nzdo__field_indexing, o)
  end

  def __extract_index_settings__(_mod, _field, _indexers, [], _opts) do
    nil
  end

  def __extract_index_settings__(mod, field, indexers, entries, opts) when is_list(entries) do
    Enum.map(entries, &(EntityMeta.__extract_index_setting__(mod, field, indexers, &1, opts)))
    |> List.flatten()
    |> Enum.filter(&(&1))
  end

  def __extract_index_setting__(_mod, field, indexers, :field = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_uint = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_int = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_bigint = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_bool = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_multi = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_multi64 = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_timestamp = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_float = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, true, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true}}))
  end

  def __extract_index_setting__(_mod, field, indexers, false, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: false}}))
  end

  def __extract_index_setting__(mod, field, indexers, :inline, opts) do
    inline = Module.get_attribute(mod, :__nzdo__inline_index)
    EntityMeta.__extract_index_setting__(mod, field, indexers, inline, opts)
  end

  def __extract_index_setting__(mod, field, indexers, index, _opts) when is_atom(index) do
    cond do
      Enum.member?(indexers, index) -> {{field, index}, %{index: true}}
      :else -> raise "Index #{inspect index} not supported. You must include `@index #{index}` before declaring #{mod} if you wish to declare settings for this index."
    end
  end

  def __extract_index_setting__(mod, field, indexers, settings, opts) when is_list(settings) do
    Enum.map(settings, &(EntityMeta.__extract_index_setting__(mod, field, indexers, &1, opts)))
  end

  def __extract_index_setting__(_mod, field, indexers, {:bits, encoding}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, bits: encoding}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:encoding, encoding}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:as, setting}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, as: setting}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:with, setting}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, with: setting}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:user_defined, setting}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, user_defined: setting}}))
  end

  def __extract_index_setting__(mod, field, indexers, {:inline, settings}, opts) do
    inline = Module.get_attribute(mod, :__nzdo__inline_index)
    EntityMeta.__extract_index_setting__(mod, field, indexers, {inline, settings}, opts)
  end

  def __extract_index_setting__(mod, field, indexers, {index, settings}, opts) when is_atom(index) do
    cond do
      Enum.member?(indexers, index) ->
        settings = is_list(settings) && settings || [settings]
        Enum.map(settings, &(EntityMeta.__extract_index_setting__(mod, field, index, indexers, &1, opts)))
      :else -> raise "Setting or Index #{inspect index} not supported. If this is an Index include `@index #{index}` before declaring #{mod}"
    end
  end

  def __extract_index_setting__(_mod, field, index, _indexers, true, _opts) do
    {{field, index}, %{index: true}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, false, _opts) do
    {{field, index}, %{index: false}}
  end


  def __extract_index_setting__(_mod, field, index, _indexers, {:bits, encoding}, _opts) do
    {{field, index}, %{index: true, bits: encoding}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:encoding, encoding}, _opts) do
    {{field, index}, %{index: true, encoding: encoding}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:as, setting}, _opts) do
    {{field, index}, %{index: true, as: setting}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:with, setting}, _opts) do
    {{field, index}, %{index: true, with: setting}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:user_defined, setting}, _opts) do
    {{field, index}, %{index: true, user_defined: setting}}
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_permission_settings__(mod, _field, _opts) do
    #entries = Module.get_attribute(mod, :permission)
    Module.delete_attribute(mod, :permission)
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_json_settings__(mod, field, opts) do
    config = Module.get_attribute(mod, :__nzdo__json_config)
    settings = Module.get_attribute(mod, :__nzdo__raw__json_format_settings, %{})
               |> EntityMeta.__extract_json_settings__(:json, mod, field, config, opts)
               |> EntityMeta.__extract_json_settings__(:json_embed, mod, field, config, opts)
               |> EntityMeta.__extract_json_settings__(:json_ignore, mod, field, config, opts)
    Module.put_attribute(mod, :__nzdo__raw__json_format_settings, settings)
  end


  # Selector Expansion
  # :* -> set of all supported formats from config map -> [list]
  # :alias (is supported or a predefined json_formatting group -> [list]
  # [aliases] -> set of format groups or formants flatten to bigger list
  # rules override in sequence however the different tags are processe3d in a different order
  # json < json_embed < json_ignore

  # include flag if not specified defaults to global settings (White list or black list, or white_list with set, or black list with set)

  # output_data structure
  # %{
  #    mobile: %{
  #                expand?: true | false,
  #                embed: nil | [rules]
  #                format: {format, Keyword.T}
  #                include: true | false, # if false don't include output

  #---------------------------------
  #
  #---------------------------------
  def __expand_json_entry__({selector, settings}, field, config, opts) do
    selector = __expand_json_selector__(selector, config, opts)
    fields = __expand_json_field__(field, config, opts)
    settings = cond do
                 is_list(settings) -> settings
                 :else -> [settings]
               end
    {selector, fields, settings}
  end
  def __expand_json_entry__({selector, fields, settings}, _field, config, opts) do
    selector = __expand_json_selector__(selector, config, opts)
    fields = __expand_json_field__(fields, config, opts)
    settings = cond do
                 is_list(settings) -> settings
                 :else -> [settings]
               end
    {selector, fields, settings}
  end

  #---------------------------------
  #
  #---------------------------------
  def __expand_json_selector__(:*, config, _opts) do
    config.supported
  end

  def __expand_json_selector__(selector, config, _opts) when is_atom(selector) do
    cond do
      g = config.selection_groups[selector][:members] -> g
      :else -> [selector]
    end
  end

  def __expand_json_selector__(selectors, config, opts) when is_list(selectors) do
    Enum.map(
      selectors,
      fn (selector) ->
        __expand_json_selector__(selector, config, opts)
      end
    )
    |> List.flatten()
    |> Enum.uniq()
  end

  #---------------------------------
  #
  #---------------------------------
  def __expand_json_field__(field, config, _opts) when is_atom(field) do
    cond do
      g = config.field_groups[field][:members] -> g
      :else -> [field]
    end
  end

  def __expand_json_field__(fields, config, opts) when is_list(fields) do
    Enum.map(
      fields,
      fn (field) ->
        __expand_json_field__(field, config, opts)
      end
    )
    |> List.flatten()
    |> Enum.uniq()
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    # {selector, fields, ...}
    # {selector, expand}
    # {selector, format: _}
    # {[selectors], ..}
    # {selector, as: "RenameTo"}
    # {selector, embed: [list]}
    Enum.reduce(
      entries || [],
      acc,
      fn (entry, acc) ->
        {selectors, fields, settings} = __expand_json_entry__(entry, field, config, opts)
        Enum.reduce(
          settings,
          acc,
          fn (s, acc) ->
            case s do
              :expand -> __set_option__(acc, selectors, fields, {:expand, true})
              :sref -> __set_option__(acc, selectors, fields, {:sref, true})
              :ignore -> __set_option__(acc, selectors, fields, {:include, false})
              :include -> __set_option__(acc, selectors, fields, {:include, true})
              {:format, _} -> __set_option__(acc, selectors, fields, s)
              {:as, _} -> __set_option__(acc, selectors, fields, s)
              {:embed, embed} when is_atom(embed) ->
                embed = Map.new([{:embed, true}])
                __set_option__(acc, selectors, fields, {:embed, embed})
              {:embed, embed} when is_list(embed) ->
                embed = Enum.map(
                          embed,
                          fn (e) ->
                            case e do
                              e when is_atom(e) -> {e, true}
                              {e, f} -> {e, f}
                              _ -> nil
                            end
                          end
                        )
                        |> Enum.filter(&(&1))
                        |> Map.new()
                __set_option__(acc, selectors, fields, {:embed, embed})
              _ -> acc
            end
          end
        )
      end
    )
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json_embed, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    Enum.reduce(
      entries,
      acc,
      fn (entry, acc) ->
        case entry do
          {selector, embed} when is_list(embed) ->
            selectors = __expand_json_selector__(selector, config, opts)
            embed = Enum.map(
                      embed,
                      fn (e) ->
                        case e do
                          e when is_atom(e) -> {e, true}
                          {e, f} -> {e, f}
                          _ -> nil
                        end
                      end
                    )
                    |> Enum.filter(&(&1))
                    |> Map.new()
            __set_option__(acc, selectors, [field], {:embed, embed})
          {selector, embed} when is_atom(embed) ->
            selectors = __expand_json_selector__(selector, config, opts)
            embed = Map.new([{:embed, true}])
            __set_option__(acc, selectors, [field], {:embed, embed})
          _ -> acc
        end
      end
    )
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json_ignore, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    Enum.reduce(
      entries,
      acc,
      fn (entry, acc) ->
        case entry do
          {selector, fields} ->
            selectors = __expand_json_selector__(selector, config, opts)
            fields = __expand_json_field__(fields, config, opts)
            __set_option__(acc, selectors, fields, {:include, false})
          selector ->
            selectors = __expand_json_selector__(selector, config, opts)
            __set_option__(acc, selectors, [field], {:include, false})
        end
      end
    )
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_option__(acc, formats, fields, {setting, setting_value}) do
    Enum.reduce(
      formats,
      acc,
      fn (format, acc) ->
        acc = update_in(acc, [format], &(&1 || %{}))
        Enum.reduce(
          fields,
          acc,
          fn (field, acc) ->
            acc = update_in(acc, [format, field], &(&1 || %{}))
            put_in(acc, [format, field, setting], setting_value)
          end
        )
      end
    )
  end



  defmacro __post_struct_definition_macro__(_) do
    macro_file = __ENV__.file
    quote do
      # Set Meta
      @file unquote(macro_file) <> "<set_meta> | #{inspect @__nzdo__base}"
      Module.put_attribute(@__nzdo__base, :__nzdo__meta, (Module.has_attribute?(__MODULE__, :meta) && Module.get_attribute(__MODULE__, :meta) || []))

      #----------------------
      # fields meta data
      #----------------------
      @file unquote(macro_file) <> "<types_map>"
      @__nzdo__field_types_map (
                                 (@__nzdo__field_types || [])
                                 |> Map.new())
      @file unquote(macro_file) <> "<field_list>"
      @__nzdo__field_list (Enum.map(@__nzdo__fields, fn ({k, _}) -> k end) -- [:initial, :meta])

      #----------------------
      # Universals Fields (always include)
      #----------------------
      @file unquote(macro_file) <> "<__nzdo_fields:1>"
      Module.put_attribute(__MODULE__, :__nzdo__fields, {:initial, nil})
      @file unquote(macro_file) <> "<__nzdo_fields:2>"
      Module.put_attribute(__MODULE__, :__nzdo__fields, {:meta, %{}})
      @file unquote(macro_file) <> "<__nzdo_fields:3>"
      Module.put_attribute(__MODULE__, :__nzdo__fields, {:vsn, @vsn})
      :ok
    end
  end

  defmacro __register__field_attributes__macro__(_) do
    quote do
      Module.delete_attribute(__MODULE__, :index)
      Module.delete_attribute(__MODULE__, :meta)
      Module.delete_attribute(__MODULE__, :persistence_layer)
      Module.delete_attribute(__MODULE__, :json_white_list)
      Module.delete_attribute(__MODULE__, :json_format_group)
      Module.delete_attribute(__MODULE__, :json_field_group)

      # Pii Attribute
      Module.register_attribute(__MODULE__, :pii, accumulate: false)

      # Field Constraints
      Module.register_attribute(__MODULE__, :enum, accumulate: false)
      Module.register_attribute(__MODULE__, :required, accumulate: false)
      Module.register_attribute(__MODULE__, :ref, accumulate: true)
      Module.register_attribute(__MODULE__, :struct, accumulate: true)

      # Field Attributes
      Module.register_attribute(__MODULE__, :__nzdo__fields, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
      Module.register_attribute(__MODULE__, :__nzdo__field_types, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__field_attributes, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__identifier_type, accumulate: false)


      #Json Encoding Instructions
      Module.register_attribute(__MODULE__, :json, accumulate: true)
      Module.register_attribute(__MODULE__, :json_embed, accumulate: true)
      Module.register_attribute(__MODULE__, :json_ignore, accumulate: true)
      Module.register_attribute(__MODULE__, :json_restrict, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__raw__json_format_settings, accumulate: false)
      Module.put_attribute(__MODULE__, :__nzdo__raw__json_format_settings, %{})

      # Indexng
      Module.register_attribute(__MODULE__, :index, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__field_indexing, accumulate: true)

      # Permissions
      Module.register_attribute(__MODULE__, :permission, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__field_permissions, accumulate: true)
    end
  end

end
