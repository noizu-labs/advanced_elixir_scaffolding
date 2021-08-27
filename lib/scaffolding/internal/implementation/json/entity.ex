defmodule Noizu.AdvancedScaffolding.Internal.Json.Entity do
  @moduledoc """
  Json DomainObject Functionality
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types

    @callback __strip_pii__(any, any) :: any
    @callback __json__() :: any
    @callback __json__(any) :: any



    def __configure__(options) do
      quote do

        # Json Settings
        @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
        Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__json_settings__macro__(unquote(options))

      end
    end

    def __implement__(options) do
      json_implementation = options[:core_implementation] || Noizu.AdvancedScaffolding.Internal.Json.Entity.Implementation.Default
      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.Json.Entity.Behaviour
        @__nzdo__json_implementation unquote(json_implementation)

        #---------------
        # Poison
        #---------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        if (__nzdo__json_provider = @__nzdo__json_provider) do
          defimpl Poison.Encoder  do
            @__nzdo__json_provider __nzdo__json_provider
            def encode(entity, options \\ nil), do: @__nzdo__json_provider.encode(entity, options)
          end
        end

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __strip_pii__(entity, level), do: @__nzdo__json_implementation.__strip_pii__(__MODULE__, entity, level)

        defoverridable [
          __strip_pii__: 2,
        ]

      end
    end


    defmacro __before_compile__(_env) do
      quote do



        #################################################
        # __json__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @doc """
          Json Encoding/Decoding settings.
        """
        def __json__(), do: @__nzdo__base.__json__()
        def __json__(property), do: @__nzdo__base.__json__(property)

      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end


  end
end
