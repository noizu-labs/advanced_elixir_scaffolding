defmodule Noizu.AdvancedScaffolding.Internal.Inspect.Entity do
  @moduledoc """
  Json DomainObject Functionality
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types

    @callback __strip_inspect__(any, any) :: any





    def __configure__(_options) do
    end

    def __implement__(options) do
      inspect_implementation = options[:core_implementation] || Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Implementation.Default
      inspect_provider = (options[:inspect_implementation] != false) && (options[:inspect_implementation] || Noizu.AdvancedScaffolding.Internal.DomainObject.Inspect)
      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Behaviour
        @__nzdo__inspect_implementation unquote(inspect_implementation)
        #---------------
        # Inspect
        #---------------
        if unquote(inspect_provider) do
          defimpl Inspect do
            def inspect(entity, opts), do: unquote(inspect_provider).inspect(entity, opts)
          end
        end

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __strip_inspect__(entity, opts), do: @__nzdo__inspect_implementation.__strip_inspect__(__MODULE__, entity, opts)

        defoverridable [
          __strip_inspect__: 2,
        ]

      end
    end


    defmacro __before_compile__(_env) do
      quote do


      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end

  end
end
