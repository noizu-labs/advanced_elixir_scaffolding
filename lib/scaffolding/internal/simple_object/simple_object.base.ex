defmodule Noizu.AdvancedScaffolding.Internal.SimpleObject.Base do

  defmodule Behaviour do
    @callback __as_record__(any, any, any, any) :: any
    @callback __as_record__(any, any, any, any, any) :: any

    @callback __as_record__!(any, any, any, any) :: any
    @callback __as_record__!(any, any, any, any, any) :: any

    @callback __as_record_type__(any, any, any, any) :: any
    @callback __as_record_type__(any, any, any, any, any) :: any

    @callback __as_record_type__!(any, any, any, any) :: any
    @callback __as_record_type__!(any, any, any, any, any) :: any

    @callback __from_record__(any, any, any) :: any
    @callback __from_record__(any, any, any, any) :: any

    @callback __from_record__!(any, any, any) :: any
    @callback __from_record__!(any, any, any, any) :: any

    @callback ecto_entity?() :: boolean
    @callback ecto_identifier(any) :: any
    @callback source(any) :: any
    @callback universal_identifier(any) :: any

    @callback __strip_pii__(any, any) :: any
    @callback __valid__(any, any) :: any
    @callback __valid__(any, any, any) :: any

    @callback __kind__() :: String.t | atom
  end

  defmodule Default do
    alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__(domain_object, %{__struct__: PersistenceLayer} = layer, identifier, entity, context, options) do
      domain_object.__as_record_type__(layer, identifier, entity, context, options)
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__!(domain_object, %{__struct__: PersistenceLayer} = layer, identifier, entity, context, options) do
      domain_object.__as_record_type__!(layer, identifier, entity, context, options)
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_record_type__(domain_object, %{__struct__: PersistenceLayer, type: :ecto} = layer, identifier, entity, context, options) do
      context = Noizu.ElixirCore.CallingContext.system(context)
      field_types = domain_object.__noizu_info__(:field_types)
      Enum.map(
        domain_object.__noizu_info__(:fields) ++ [:identifier],
        fn (field) ->
          cond do
            field == :identifier -> {:identifier, identifier}
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
              type.handler.cast(entry[:source], entry[:segment], source, type, layer, context, options)
            Map.has_key?(entity, field) -> {field, get_in(entity, [Access.key(field)])}
            :else -> nil
          end
        end
      )
      |> List.flatten()
      |> Enum.filter(&(&1))
      |> layer.table.__struct__()
    end

    def __as_record_type__(_domain_object, %{__struct__: PersistenceLayer} = _layer, _identifier, _entity, _context, _options), do: nil

    def __as_record_type__!(domain_object, layer, identifier, entity, context, options), do: domain_object.__as_record_type__(layer, identifier, entity, context, options)

    #-----------------------------------
    #
    #-----------------------------------
    def __from_record__(_m, %{__struct__: PersistenceLayer} = _layer, %{entity: temp}, _context, _options), do: temp
    def __from_record__(_m, %{__struct__: PersistenceLayer} = _layer, _ref, _context, _options), do: nil

    def __from_record__!(_m, %{__struct__: PersistenceLayer} = _layer, %{entity: temp}, _context, _options), do: temp
    def __from_record__!(_m, %{__struct__: PersistenceLayer} = _layer, _ref, _context, _options), do: nil
  end


  @doc """
  Configure SimpleObject fields and internals.
  """
  def __noizu_struct__(caller, options, block) do
    options = Macro.expand(options, __ENV__)

    struct_implementation_provider = options[:implementation] || Noizu.AdvancedScaffolding.Internal.SimpleObject.Base

    inspect_provider = cond do
                         options[:inspect_implementation] == false -> false
                         :else -> options[:inspect_implementation] || Noizu.AdvancedScaffolding.Internal.DomainObject.Inspect
                       end

    process_config = quote do
                       require Noizu.DomainObject
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity
                       require Noizu.AdvancedScaffolding.Internal.Helpers
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros
                       import Noizu.ElixirCore.Guards
                       @options unquote(options)


                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__struct_defined, unquote(caller))

                       #--------------------
                       # Extract configuration details from provided options/set attributes/base attributes/config methods.
                       #--------------------
                       Noizu.AdvancedScaffolding.Internal.Helpers.__prepare_simple_object__(unquote(options))

                       #----------------------
                       # Derives
                       #----------------------
                       @__nzdo__derive Noizu.Entity.Protocol
                       @__nzdo__derive Noizu.RestrictedAccess.Protocol

                       # Prep attributes for loading individual fields.
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros.__register__field_attributes__macro__(unquote(options))

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
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
                         unquote(block)
                       after
                         :ok
                       end

                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros.__post_struct_definition_macro__(unquote(options))


                     end

    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields

               end

    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(process_config)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(generate)

      #---------------
      # Poison
      #---------------
      if (@__nzdo__json_provider) do
        __nzdo__json_provider = @__nzdo__json_provider
        defimpl Poison.Encoder do
          @__nzdo__json_provider __nzdo__json_provider
          def encode(entity, options \\ nil), do: @__nzdo__json_provider.encode(entity, options)
        end
      end

      #---------------
      # Inspect
      #---------------
      if unquote(inspect_provider) do
        defimpl Inspect do
          def inspect(entity, opts), do: unquote(inspect_provider).inspect(entity, opts)
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use unquote(struct_implementation_provider)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @before_compile unquote(struct_implementation_provider)
      @after_compile unquote(struct_implementation_provider)
    end
  end


  defmacro __using__(options \\ nil) do
    options = Macro.expand(options, __ENV__)
    kind = options[:kind]
    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
      @__nzdo__persistence_imp Noizu.AdvancedScaffolding.Internal.SimpleObject.Base.Default
      @__nzdo__internal_imp Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Default
      @__nzdo__core_imp Noizu.AdvancedScaffolding.Internal.Core.Entity.Implementation.Default
      @__nzdo__index_imp Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Default
      @__nzso_kind unquote(kind) || (Module.has_attribute?(__MODULE__, :kind) && Module.get_attribute(__MODULE__, :kind)) || __MODULE__

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __as_record__(%{__struct__: PersistenceLayer} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record__(__MODULE__, layer, identifier, entity, context, options)
      def __as_record__!(%{__struct__: PersistenceLayer} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record__!(__MODULE__, layer, identifier, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __as_record_type__(%{__struct__: PersistenceLayer} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record_type__(__MODULE__, layer, identifier, entity, context, options)
      def __as_record_type__!(%{__struct__: PersistenceLayer} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record_type__!(__MODULE__, layer, identifier, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __from_record__(%{__struct__: PersistenceLayer} = layer, record, context, options \\ nil), do: @__nzdo__persistence_imp.__from_record__(__MODULE__, layer, record, context, options)
      def __from_record__!(%{__struct__: PersistenceLayer} = layer, record, context, options \\ nil), do: @__nzdo__persistence_imp.__from_record__!(__MODULE__, layer, record, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def ecto_entity?(), do: false
      def ecto_identifier(_), do: nil
      def source(_), do: nil
      def universal_identifier(_), do: nil



      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __strip_pii__(entity, level), do: Noizu.AdvancedScaffolding.Internal.Json.Entity.Implementation.Default.__strip_pii__(__MODULE__, entity, level)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __strip_inspect__(entity, opts), do: Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Implementation.Default.__strip_inspect__(__MODULE__, entity, opts)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __valid__(%{__struct__: __MODULE__} = entity, context, options \\ nil), do: @__nzdo__core_imp.__valid__(__MODULE__, entity, context, options)


      def __kind__(), do: @__nzso_kind

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        __as_record__: 4,
        __as_record__: 5,
        __as_record__!: 4,
        __as_record__!: 5,
        __as_record_type__: 4,
        __as_record_type__: 5,
        __as_record_type__!: 4,
        __as_record_type__!: 5,
        __from_record__: 3,
        __from_record__: 4,
        __from_record__!: 3,
        __from_record__!: 4,

        ecto_entity?: 0,
        ecto_identifier: 1,
        source: 1,
        universal_identifier: 1,

        __strip_pii__: 2,
        __valid__: 2,
        __valid__: 3,
        __kind__: 0,
      ]
    end
  end


  defmacro __before_compile__(_) do
    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__poly_settings  %{
        poly: @__nzdo__poly?,
        support: @__nzdo__poly_support,
        base: @__nzdo__poly_base
      }
      @__nzdo__meta__map Map.new(@__nzdo__meta || [])




      #-------
      # type lookups
      #--------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def vsn(), do: @vsn
      def __base__(), do: @__nzdo__base
      def __object__(), do: __MODULE__

      #################################################
      # __nmid__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __nmid__(), do: __nmid__(:all)
      def __nmid__(:all) do
        %{
          generator: __nmid__(:generator),
          sequencer: __nmid__(:sequencer),
          bare: __nmid__(:bare),
          index: __nmid__(:index),
        }
      end
      def __nmid__(:generator), do: @__nzdo__nmid_generator
      def __nmid__(:sequencer), do: @__nzdo__nmid_sequencer
      def __nmid__(:bare), do: @__nzdo__nmid_bare

      if @__nzdo__nmid_index do
        def __nmid__(:index), do: @__nzdo__nmid_index
      else
        def __nmid__(:index) do
          cond do
            !Kernel.function_exported?(@__nzdo__schema_helper, :__noizu_info__, 1) -> nil
            v = apply(@__nzdo__schema_helper, :__noizu_info__, [:nmid_indexes])[__MODULE__] -> v
            :else -> nil
          end
        end
      end



      #################################################
      # __indexing__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
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

      #################################################
      # __persistence__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo_persistence Noizu.AdvancedScaffolding.Schema.PersistenceSettings.update_schema_fields(@__nzdo_persistence, @__nzdo__field_types_map)
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

      #################################################
      # __noizu_info__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo_associated_types (
                                 Enum.map(@__nzdo_persistence__by_table || %{}, fn ({k, v}) -> {k, v.type} end) ++ Enum.map(
                                   @__nzdo__poly_support || [],
                                   fn (k) -> {Module.concat([k, "Entity"]), :poly} end
                                 ))
                               |> Map.new()
      @__nzdo__json_config put_in(@__nzdo__json_config, [:format_settings], @__nzdo__raw__json_format_settings)
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
      @__nzdo__persisted_fields Enum.filter(@__nzdo__field_list -- [:initial, :__transient__], &(!@__nzdo__field_attributes_map[&1][:transient]))
      @__nzdo__transient_fields Enum.filter(@__nzdo__field_list, &(@__nzdo__field_attributes_map[&1][:transient])) ++ [:initial, :__transient__]

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __noizu_info__() do
        Enum.map(
          [
            :type,
            :base,
            :struct,
            :kind,
            :restrict_provider,
            :poly,
            :json_configuration,
            :identifier_type,
            :fields,
            :field_attributes,
            :field_permissions,
            :field_types,
            :persistence,
            :associated_types,
            :indexing,
            :meta
          ],
          &({&1, __noizu_info__(&1)})
        )
      end

      def __noizu_info__(:type), do: :simple
      def __noizu_info__(:base), do: @__nzdo__base
      def __noizu_info__(:struct), do: __MODULE__
      def __noizu_info__(:kind), do: __kind__()
      def __noizu_info__(:restrict_provider), do: nil
      def __noizu_info__(:poly), do: @__nzdo__poly_settings
      def __noizu_info__(:json_configuration), do: @__nzdo__json_config
      def __noizu_info__(:identifier_type), do: @__nzdo__identifier_type
      def __noizu_info__(:fields), do: @__nzdo__field_list
      def __noizu_info__(:persisted_fields), do: @__nzdo__persisted_fields
      def __noizu_info__(:field_attributes), do: @__nzdo__field_attributes_map
      def __noizu_info__(:field_permissions), do: @__nzdo__field_permissions_map
      def __noizu_info__(:field_types), do: @__nzdo__field_types_map
      def __noizu_info__(:persistence), do: __persistence__()
      def __noizu_info__(:associated_types), do: nil
      def __noizu_info__(:indexing), do: __indexing__()
      def __noizu_info__(:meta), do: @__nzdo__meta__map

      #################################################
      # __fields__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __fields__() do
        Enum.map([:fields, :persisted, :types, :json, :attributes, :permissions], &({&1,__fields__(&1)}))
      end
      def __fields__(:fields), do: @__nzdo__field_list
      def __fields__(:persisted), do: @__nzdo__persisted_fields
      def __fields__(:transient), do: @__nzdo__transient_fields
      def __fields__(:types), do: @__nzdo__field_types_map
      def __fields__(:json), do: @__nzdo__json_config
      def __fields__(:attributes), do: @__nzdo__field_attributes_map
      def __fields__(:permissions), do: @__nzdo__field_permissions_map


      #################################################
      # __json__
      #################################################
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __json__(), do: __json__(:all)
      def __json__(:all) do
        Enum.map([:provider, :default, :formats, :white_list, :format_groups, :field_groups], &({&1, __json__(&1)}))
      end
      def __json__(:provider), do: @__nzdo__json_provider
      def __json__(:default), do: @__nzdo__json_format
      def __json__(:formats), do: @__nzdo__json_supported_formats
      def __json__(:white_list), do: @__nzdo__json_white_list
      def __json__(:format_groups), do: @__nzdo__json_format_groups
      def __json__(:field_groups), do: @__nzdo__json_field_groups

      @file __ENV__.file

    end
  end

  def __after_compile__(_env, _bytecode) do
    # Validate Generated Object
    :ok
  end


end
