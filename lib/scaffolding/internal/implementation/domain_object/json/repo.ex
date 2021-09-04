#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Json.Repo do
  @moduledoc """
  Json DomainObject Functionality
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types
    @callback __json__() :: any
    @callback __json__(any) :: any



    def __configure__(_options) do
      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.Json.Repo.Behaviour
      end
    end

    def __implement__(_options) do
    end


    defmacro __before_compile__(_env) do
      quote do

        #################################################
        # __json__
        #################################################
        def __json__(), do: @__nzdo__base.__json__()
        def __json__(property), do: @__nzdo__base.__json__(property)

        defoverridable [
        __json__: 0,
        __json__: 1
        ]
      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end
end
