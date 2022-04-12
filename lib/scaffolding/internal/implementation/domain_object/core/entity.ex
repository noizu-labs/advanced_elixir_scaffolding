#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Core.Entity do
  @moduledoc """
  ERP related DomainObject Implementation and Core Domain Object functionality.
  """

  defmodule Behaviour do
    alias Noizu.AdvancedScaffolding.Types
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
    @callback __id_to_string__(Types.identifier_type, any) :: boolean
    @callback __string_to_id__(Types.identifier_type, any) :: boolean


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

    def __configure__(options) do
      quote do
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

      end
    end

    def __implement__(options) do
      core_implementation = options[:core_implementation] || Noizu.AdvancedScaffolding.Internal.Core.Entity.Implementation.Default
      quote do
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
        def __valid_identifier__(_), do: true

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __sref_section_regex__(type), do: @__nzdo__implementation.__sref_section_regex__(__MODULE__, type)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __id_to_string__(type, id), do: @__nzdo__implementation.__id_to_string__(__MODULE__, type, id)
        def __id_to_string__(id), do: @__nzdo__implementation.__id_to_string__(__MODULE__, @__nzdo__identifier_type, id)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __string_to_id__(id), do: @__nzdo__implementation.__string_to_id__(__MODULE__, @__nzdo__identifier_type, id)
        def __string_to_id__(type, id), do: @__nzdo__implementation.__string_to_id__(__MODULE__, type, id)


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
            def id("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.id(__MODULE__.ref(ref))
            def id(ref), do: @__nzdo__implementation.id(__MODULE__, ref)
            # ref
            #-----------------
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            def ref("ref.#{@__nzdo__sref}{" <> id) do
              identifier = case __string_to_id__(String.slice(id, 0..-2)) do
                             {:ok, v} -> v
                             {:error, _} -> nil
                             v -> v
                           end
              identifier && {:ref, __MODULE__, identifier}
            end
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            def ref("ref.#{@__nzdo__sref}." <> id) do
              identifier = case __string_to_id__(id) do
                             {:ok, v} -> v
                             {:error, _} -> nil
                             v -> v
                           end
              identifier && {:ref, __MODULE__, identifier}
            end
            def ref(ref), do: @__nzdo__implementation.ref(__MODULE__, ref)
            # sref
            #-----------------
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            def sref("ref.#{@__nzdo__sref}" <> _ = ref), do: ref
            def sref(ref), do: @__nzdo__implementation.sref(__MODULE__, ref)
            # entity
            #-----------------
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            def entity("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.entity(__MODULE__.ref(ref))
            def entity(ref, options \\ nil), do: @__nzdo__implementation.entity(__MODULE__, ref, options)
            # entity!
            #-----------------
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            def entity!("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.entity!(__MODULE__.ref(ref))
            def entity!(ref, options \\ nil), do: @__nzdo__implementation.entity!(__MODULE__, ref, options)



          :else ->
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            def id(ref), do: @__nzdo__implementation.id(__MODULE__, ref)
            # ref
            #-----------------
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
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



        def id_ok(o) do
          r = ref(o)
          r && {:ok, r} || {:error, o}
        end
        def ref_ok(o) do
          r = ref(o)
          r && {:ok, r} || {:error, o}
        end
        def sref_ok(o) do
          r = sref(o)
          r && {:ok, r} || {:error, o}
        end
        def entity_ok(o, options \\ %{}) do
          r = entity(o, options)
          r && {:ok, r} || {:error, o}
        end
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
          __id_to_string__: 2,
          __string_to_id__: 1,
          __string_to_id__: 2,


          __valid__: 2,
          __valid__: 3,

          id: 1,
          ref: 1,
          sref: 1,
          entity: 1,
          entity: 2,
          entity!: 1,
          entity!: 2,
          record: 1,
          record: 2,
          record!: 1,
          record!: 2,


          id_ok: 1,
          ref_ok: 1,
          sref_ok: 1,
          entity_ok: 1,
          entity_ok: 2,
          entity_ok!: 1,
          entity_ok!: 2,

          has_permission?: 3,
          has_permission?: 4,
          has_permission!: 3,
          has_permission!: 4,
          version_change: 3,
          version_change: 4,
          version_change!: 3,
          version_change!: 4,
        ]

      end
    end


    defmacro __before_compile__(_env) do
      quote do


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

        @__nzdo__persisted_fields Enum.filter(@__nzdo__field_list -- [:initial, :__transient__], &(!@__nzdo__field_attributes_map[&1][:transient]))
        @__nzdo__transient_fields Enum.filter(@__nzdo__field_list, &(@__nzdo__field_attributes_map[&1][:transient])) ++ [:initial, :__transient__]

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

      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end



end
