#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.EntityIndex.Base do
  @moduledoc """
  Base Indexing Functionality
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types
    @callback __indexing__() :: any
    @callback __indexing__(any) :: any

    def __configure__(options) do
      index_implementation = options[:index_implementation] || Noizu.AdvancedScaffolding.Internal.DomainObject.Index
      quote do
        @nzdo__index_implementation unquote(index_implementation)
      end
    end


    defmacro __before_compile__(env) do
      nzdo__index_implementation = Module.get_attribute(env.module, :nzdo__index_implementation)
      nzdo__entity = Module.get_attribute(env.module, :__nzdo__entity)
      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.EntityIndex.Base.Behaviour
        #################################################
        # __indexing__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __indexing__(), do: @__nzdo__entity.__indexing__()
        def __indexing__(setting), do: @__nzdo__entity.__indexing__(setting)

        #--------------------
        # Index
        #--------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        if Module.has_attribute?(__MODULE__, :__nzdo__inline_index) && Module.get_attribute(__MODULE__, :__nzdo__inline_index) do
          defmodule Index do
            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            require unquote(nzdo__index_implementation)

            @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
            unquote(nzdo__index_implementation).noizu_index(entity: unquote(nzdo__entity), inline: true) do
            end
          end
        end
        @file __ENV__.file
      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end




end
