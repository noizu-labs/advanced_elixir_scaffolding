#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Core.Repo do
  @moduledoc """
  Core DomainObject Functionality
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


    @callback has_permission?(any, any, any, any) :: boolean
    @callback has_permission!(any, any, any, any) :: boolean

    def __configure__(_options) do
      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.Core.Repo.Behaviour
      end
    end

    def __implement__(_options) do
      quote do

        @__nzdo__repo_default Noizu.AdvancedScaffolding.Internal.Core.Repo.Implementation.Default


        #################################################
        #
        #################################################
        def vsn(), do: @__nzdo__base.vsn()
        def __base__(), do: @__nzdo__base
        def __poly_base__(), do: @__nzdo__poly_base
        def __entity__(), do: @__nzdo__base.__entity__()
        def __repo__(), do: __MODULE__
        def __sref__(), do: @__nzdo__base.__sref__()
        def __erp__(), do: @__nzdo__base.__erp__()
        def id(ref), do: @__nzdo__base.id(ref)
        def ref(ref), do: @__nzdo__base.ref(ref)
        def sref(ref), do: @__nzdo__base.sref(ref)

        def entity(ref, options \\ nil), do: @__nzdo__base.entity(ref, options)
        def entity!(ref, options \\ nil), do: @__nzdo__base.entity!(ref, options)

        def record(ref, options \\ nil), do: @__nzdo__base.record(ref, options)
        def record!(ref, options \\ nil), do: @__nzdo__base.record!(ref, options)

        #---------------------
        #
        #---------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def has_permission?(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission?(__MODULE__, permission, context, nil)
        def has_permission?(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission?(__MODULE__, permission, context, options)
        def has_permission?(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission?(__MODULE__, ref, permission, context, nil)
        def has_permission?(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission?(__MODULE__, ref, permission, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def has_permission!(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission!(__MODULE__, permission, context, nil)
        def has_permission!(permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission!(__MODULE__, permission, context, options)
        def has_permission!(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context), do: @__nzdo__repo_default.has_permission!(__MODULE__, ref, permission, context, nil)
        def has_permission!(ref, permission, %{__struct__: Noizu.ElixirCore.CallingContext} = context, options), do: @__nzdo__repo_default.has_permission!(__MODULE__, ref, permission, context, options)




        defoverridable [


          vsn: 0,
          __entity__: 0,
          __base__: 0,
          __poly_base__: 0,
          __repo__: 0,
          __sref__: 0,
          __erp__: 0,

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

          has_permission?: 2,
          has_permission?: 3,
          has_permission?: 4,

          has_permission!: 2,
          has_permission!: 3,
          has_permission!: 4,
        ]
      end
    end


    defmacro __before_compile__(_env) do
      quote do


        #################################################
        # __noizu_info__
        #################################################
        def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :repo)
        def __noizu_info__(:type), do: :repo
        def __noizu_info__(report), do: @__nzdo__base.__noizu_info__(report)

        #################################################
        # __fields__
        #################################################
        def __fields__, do: @__nzdo__base.__fields__
        def __fields__(setting), do: @__nzdo__base.__fields__(setting)

        #################################################
        # __enum__
        #################################################
        def __enum__(), do: @__nzdo__base.__enum__()
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
