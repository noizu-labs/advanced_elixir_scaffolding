defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Struct.DefaultIndexProvider do

  defmacro __using__(_options \\ nil) do
    quote do
      # We forward down tot he entity profider's implementations
      @__nzdo__index_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultIndexProvider.Default

      def __write_index__(entity, context, options \\ nil), do: @__nzdo__index_imp.__write_index__(__MODULE__, entity, context, options)
      def __update_index__(entity, context, options \\ nil), do: @__nzdo__index_imp.__update_index__(__MODULE__, entity, context, options)
      def __delete_index__(entity, context, options \\ nil), do: @__nzdo__index_imp.__delete_index__(__MODULE__, entity, context, options)

      defoverridable [
        __write_index__: 2,
        __write_index__: 3,
        __update_index__: 2,
        __update_index__: 3,
        __delete_index__: 2,
        __delete_index__: 3,
      ]
    end
  end

end
