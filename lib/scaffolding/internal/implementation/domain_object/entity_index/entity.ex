defmodule Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity do
  @moduledoc """
  Search Indexing DomainObject Functionality
  """

  defmodule Behaviour do
    #alias Noizu.AdvancedScaffolding.Types




    @callback __write_indexes__(any, any, any) :: any
    @callback __update_indexes__(any, any, any) :: any
    @callback __delete_indexes__(any, any, any) :: any

    @callback __write_index__(any, any, any, any, any) :: any
    @callback __update_index__(any, any, any, any, any) :: any
    @callback __delete_index__(any, any, any, any, any) :: any

    @callback __indexing__() :: any
    @callback __indexing__(any) :: any


    def __configure__(options) do
      quote do
        # Load Sphinx Settings from base.
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__sphinx__macro__(unquote(options))

      end
    end

    def __implement__(options) do
      entity_index_implementation = options[:core_implementation] || Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Implementation.Default

      quote do

        @behaviour Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Behaviour

        alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
        @__nzdo__entity_index_implementation unquote(entity_index_implementation)

        #------------------------------
        #
        #------------------------------
        def __write_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__entity_index_implementation.__write_index__(__MODULE__, entity, index, settings, context, options)

        def __update_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__entity_index_implementation.__update_index__(__MODULE__, entity, index, settings, context, options)

        def __delete_index__(entity, index, settings, context, options \\ nil), do: @__nzdo__entity_index_implementation.__delete_index__(__MODULE__, entity, index, settings, context, options)

        #------------------------------
        #
        #------------------------------
        def __write_indexes__(entity, context, options \\ nil) do
          Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __write_index__(entity, index, settings, context, options) end)
          entity
        end

        def __update_indexes__(entity, context, options \\ nil) do
          Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __update_index__(entity, index, settings, context, options) end)
          entity
        end

        def __delete_indexes__(entity, context, options \\ nil) do
          Enum.map(entity.__struct__.__indexing__, fn({index, settings}) -> __delete_index__(entity, index, settings, context, options) end)
          entity
        end

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


    defmacro __before_compile__(_env) do
      quote do



        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @__nzdo__indexes Enum.reduce(
                           List.flatten(@__nzdo__field_indexing || []),
                           @__nzdo__indexes,
                           fn ({{field, index}, indexing}, acc) ->
                             cond do
                               acc[index][:fields][field] == nil ->
                                 put_in(acc, [index, :fields, field], indexing)
                               e = acc[index][:fields][field] ->
                                 e = Enum.reduce(indexing, e, fn ({k, v}, acc) -> put_in(acc, [k], v) end)
                                 put_in(acc, [index, :fields, field], e)
                             end
                           end
                         )

        #################################################
        # __indexing__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @doc """
          Search Index Configuration
        """
        def __indexing__(), do: __indexing__(:indexes)

        @doc """
          Search Index Configuration
        """
        def __indexing__(:indexes), do: @__nzdo__indexes


      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end

  end
end
