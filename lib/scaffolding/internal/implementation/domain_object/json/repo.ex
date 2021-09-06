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

    def __implement__(options) do
      json_provider = options[:json_provider]
      disable_json_imp = (json_provider == false)
      quote do
        jp = Module.get_attribute(__MODULE__, :json_provider, nil)
        djp = (jp == false)
        @__nzdo__repo_json_provider (!(djp || unquote(disable_json_imp))) && (unquote(json_provider) || Module.get_attribute(__MODULE__, :json_provider, Noizu.Poison.RepoEncoder))

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        if (__nzdo__json_provider = @__nzdo__repo_json_provider) do
          defimpl Poison.Encoder  do
            @__nzdo__repo_json_provider __nzdo__json_provider
            def encode(entity, options \\ nil), do: @__nzdo__repo_json_provider.encode(entity, options)
          end
        end
      end
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
