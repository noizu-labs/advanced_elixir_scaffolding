#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.EntityIndex.Repo do
  @moduledoc """
  Index DomainObject Functionality
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types


    @callback __indexing__() :: any
    @callback __indexing__(any) :: any

    def __configure__(_options) do
      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.EntityIndex.Repo.Behaviour
      end
    end

    def __implement__(_options) do
    end


    defmacro __before_compile__(_env) do
      quote do

        #################################################
        # __indexing__
        #################################################
        def __indexing__(), do: @__nzdo__base.__indexing__()
        def __indexing__(setting), do: @__nzdo__base.__indexing__(setting)

        defoverridable [
          __indexing__: 0,
          __indexing__: 1
        ]
      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end
end
