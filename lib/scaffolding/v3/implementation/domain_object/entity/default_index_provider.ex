defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultIndexProvider do

  defmodule Default do

    def __write_index__(domain_object, _entity, _index, _settings, _context, _options) do
      IO.puts "TODO - #{domain_object} - iterate over indexes (if any) and call their insert methods."
    end
    def __update_index__(domain_object, _entity, _index, _settings, _context, _options) do
      IO.puts "TODO - #{domain_object} - iterate over indexes (if any) and call their update methods."
    end
    def __delete_index__(domain_object, _entity, _index, _settings, _context, _options) do
      IO.puts "TODO - #{domain_object} - iterate over indexes (if any) and call their delete methods."
    end

  end


  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__index_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultIndexProvider.Default


      #------------------------------
      #
      #------------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __write_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__index_imp.__write_index__(__MODULE__, entity, index, settings, context, options)

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __update_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__index_imp.__update_index__(__MODULE__, entity, index, settings, context, options)

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __delete_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__index_imp.__delete_index__(__MODULE__, entity, index, settings, context, options)

      #------------------------------
      #
      #------------------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __write_indexes__(entity, context, options \\ nil) do
        Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __write_index__(entity, index, settings, context, options) end)
        entity
      end

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __update_indexes__(entity, context, options \\ nil) do
        Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __update_index__(entity, index, settings, context, options) end)
        entity
      end

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def __delete_indexes__(entity, context, options \\ nil) do
        Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __delete_index__(entity, index, settings, context, options) end)
        entity
      end

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      defoverridable [
        __write_index__: 4,
        __write_index__: 5,

        __update_index__: 4,
        __update_index__: 5,

        __delete_index__: 4,
        __delete_index__: 5,

        __write_indexes__: 2,
        __write_indexes__: 3,

        __update_indexes__: 2,
        __update_indexes__: 3,

        __delete_indexes__: 2,
        __delete_indexes__: 3,
      ]
    end
  end

end
