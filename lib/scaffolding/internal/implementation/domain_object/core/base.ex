#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Core.Base do
  @moduledoc """
  ERP related DomainObject Implementation and Core Domain Object functionality.
  """

  defmodule Behaviour do
    alias Noizu.AdvancedScaffolding.Types

    @callback vsn() :: float
    @callback __entity__() :: module
    @callback __base__() :: module
    @callback __poly_base__() :: module
    @callback __repo__() :: module
    @callback __sref__() :: String.t
    @callback __erp__() :: module

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
      nmid_generator = options[:nmid_generator]
      nmid_sequencer = options[:nmid_sequencer]
      nmid_index = options[:nmid_index]
      auto_generate = options[:auto_generate]

      quote do
        require Noizu.AdvancedScaffolding.Internal.Helpers
        Module.register_attribute(__MODULE__, :index, accumulate: true)
        Module.register_attribute(__MODULE__, :persistence_layer, accumulate: true)
        Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
        Module.register_attribute(__MODULE__, :__nzdo__entity, accumulate: false)
        Module.register_attribute(__MODULE__, :__nzdo__struct, accumulate: false)
        Module.register_attribute(__MODULE__, :json_white_list, accumulate: false)
        Module.register_attribute(__MODULE__, :json_format_group, accumulate: true)
        Module.register_attribute(__MODULE__, :json_field_group, accumulate: true)
        Module.register_attribute(__MODULE__, :poly_support, accumulate: true)


        if v = unquote(nmid_generator) do
          Module.put_attribute(__MODULE__, :nmid_generator, v)
        end
        if v = unquote(nmid_sequencer) do
          Module.put_attribute(__MODULE__, :nmid_sequencer, v)
        end
        if v = unquote(nmid_index) do
          Module.put_attribute(__MODULE__, :nmid_index, v)
        end
        if unquote(auto_generate) != nil do
          Module.put_attribute(__MODULE__, :auto_generate, unquote(auto_generate))
        end
      end
    end


    defmacro __before_compile__(_env) do
      quote do

        @behaviour Noizu.AdvancedScaffolding.Internal.Core.Base.Behaviour
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @__nzdo__entity Module.get_attribute(__MODULE__, :__nzdo__entity)
        @__nzdo__struct Module.get_attribute(__MODULE__, :__nzdo__struct)
        @__nzdo__enum_type nil
        if Module.get_attribute(__MODULE__, :__nzdo__enum_list) do
          @__nzdo__enum_type Module.concat([__MODULE__, "Ecto.EnumType"])
        end

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def vsn(), do: @vsn
        def __base__(), do: __MODULE__
        def __poly_base__(), do: @__nzdo__poly_base
        def __entity__(), do: @__nzdo__entity
        if @__nzdo__poly_base == __MODULE__ do
          def __repo__(), do: @__nzdo__repo
        else
          def __repo__(), do: __poly_base__().__repo__()
        end
        def __sref__(), do: @__nzdo__sref
        def __kind__(), do: @__nzdo__kind
        def __repo_kind__(), do: "Repo(#{@__nzdo__kind})"
        def __erp__(), do: @__nzdo__entity




        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def id(ref), do: @__nzdo__entity.id(ref)
        def ref(ref), do: @__nzdo__entity.ref(ref)
        def sref(ref), do: @__nzdo__entity.sref(ref)
        def entity(ref, options \\ nil), do: @__nzdo__entity.entity(ref, options)
        def entity!(ref, options \\ nil), do: @__nzdo__entity.entity!(ref, options)
        def record(ref, options \\ nil), do: @__nzdo__entity.record(ref, options)
        def record!(ref, options \\ nil), do: @__nzdo__entity.record!(ref, options)



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


        @__nzdo__poly_settings  %{
          poly: @__nzdo__poly?,
          support: @__nzdo__poly_support,
          base: @__nzdo__poly_base
        }
        @__nzdo__meta__map Map.new(@__nzdo__meta || [])




        #################################################
        # __noizu_info__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __noizu_info__(), do: __noizu_info__(:all)
        def __noizu_info__(:all) do
          Enum.map(
            [
              :type,
              :base,
              :entity,
              :struct,
              :repo,
              :sref,
              :kind,
              :restrict_provider,
              :poly,
              :json_configuration,
              :identifier_type,
              :fields,
              :field_attributes,
              :field_permissions,
              :field_types,
              :associated_types,
              :persistence,
              :indexing,
              :meta,
              :enum
            ],
            &({&1, __noizu_info__(&1)})
          )
        end
        def __noizu_info__(:type), do: :base
        def __noizu_info__(:base), do: __MODULE__
        def __noizu_info__(:entity), do: @__nzdo__entity
        def __noizu_info__(:struct), do: @__nzdo__entity
        if @__nzdo__poly_base == __MODULE__ do
          def __noizu_info__(:repo), do: @__nzdo__repo
        else
          def __noizu_info__(:repo), do: __poly_base__().__repo__()
        end
        def __noizu_info__(:sref), do: __sref__()
        def __noizu_info__(:kind), do: __kind__()
        def __noizu_info__(:restrict_provider), do: nil
        def __noizu_info__(:poly), do: @__nzdo__poly_settings
        @entity_driven_properties [
          :json_configuration,
          :identifier_type,
          :fields,
          :persisted_fields,
          :field_attributes,
          :field_permissions,
          :field_types,
          :associated_types
        ]
        def __noizu_info__(property) when property in @entity_driven_properties, do: @__nzdo__entity.__noizu_info__(property)
        def __noizu_info__(:persistence), do: __persistence__()
        def __noizu_info__(:indexing), do: __indexing__()
        def __noizu_info__(:meta), do: @__nzdo__meta__map
        def __noizu_info__(:enum), do: __enum__()

        #################################################
        # __fields__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __fields__(), do: @__nzdo__entity.__fields__()
        def __fields__(setting), do: @__nzdo__entity.__fields__(setting)

        #################################################
        # __enum__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __enum__(), do: __enum__(:all)
        def __enum__(:all) do
          Enum.map([:list, :default, :is_enum?, :value_type, :type], &({&1, __enum__(&1)}))
        end
        def __enum__(:list), do: @__nzdo__enum_list
        def __enum__(:default), do: @__nzdo__enum_default_value
        def __enum__(:is_enum?), do: @__nzdo__enum_table
        def __enum__(:value_type), do: @__nzdo__enum_ecto_type
        def __enum__(:type), do: @__nzdo__enum_type


        #--------------------
        # EctoEnum
        #--------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        domain_object = __MODULE__
        has_list = Module.get_attribute(__MODULE__, :__nzdo__enum_type) || false

        if has_list do
          defmodule Ecto.EnumType do
            require Noizu.AdvancedScaffolding.Internal.Ecto.EnumType
            Noizu.AdvancedScaffolding.Internal.Ecto.EnumType.enum_type()
          end

          def atoms(), do: @__nzdo__enum_type.atom_to_enum()
        end



      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end




end
