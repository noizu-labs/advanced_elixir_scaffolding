#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Persistence.Base do
  @moduledoc """
  Base Persistence
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types
    @callback __nmid__() :: any
    @callback __nmid__(any) :: any

    @callback __persistence__() :: any
    @callback __persistence__(any) :: any
    @callback __persistence__(any, any) :: any

    def __configure__(_options) do

    end


    defmacro __before_compile__(_env) do


      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.Persistence.Base.Behaviour
        #################################################
        # __nmid__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __nmid__(), do: __nmid__(:all)
        def __nmid__(:all), do: @__nzdo__entity.__nmid__(:all)
        def __nmid__(:generator), do: @__nzdo__nmid_generator
        def __nmid__(:sequencer), do: @__nzdo__nmid_sequencer
        def __nmid__(:bare), do: @__nzdo__nmid_bare
        def __nmid__(:index), do: @__nzdo__entity.__nmid__(:index)
        # , do: @__nzdo__noizu_domain_object_schema.__noizu_info__(@nmid_source)[@__nzdo__nmid_sequencer]

        #################################################
        # __persistence__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __persistence__(), do: @__nzdo__entity.__persistence__()
        def __persistence__(setting), do: @__nzdo__entity.__persistence__(setting)
        def __persistence__(selector, setting), do: @__nzdo__entity.__persistence__(selector, setting)


        #--------------------
        # Ref
        #--------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        cond do
          Module.get_attribute(__MODULE__, :__nzdo_enum_ref) ->
            e = @__nzdo__entity
            b = __MODULE__
            defmodule Ecto.EnumReference do
              use Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Enum, entity: e, base: b
            end

          Module.get_attribute(__MODULE__, :__nzdo_universal_ref) ->
            e = @__nzdo__entity
            t = Module.get_attribute(__MODULE__, :reference_type)
            defmodule Ecto.UniversalReference do
              use Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Universal, entity: e, reference_type: t
            end

          Module.get_attribute(__MODULE__, :__nzdo_basic_ref) ->
            e = @__nzdo__entity
            defmodule Ecto.Reference do
              use Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Basic, entity: e
            end
          :else -> :ok
        end

      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end




end
