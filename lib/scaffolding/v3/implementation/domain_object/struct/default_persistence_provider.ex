defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Struct.DefaultPersistenceProvider do

  defmodule Default do
    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__(domain_object, table, identifier, entity, context, options) do
      layer = domain_object.__persistence__(:table)[table]
      cond do
        layer == nil -> nil
        layer.type == :mnesia -> nil # structs are not persisted to mnesia, they are embedded in other objects.
        layer.type == :ecto -> domain_object.__as_ecto_record__(table, identifier, entity, context, options)
        layer.type == :redis -> domain_object.__as_redis_record__(table, identifier, entity, context, options)
        :else -> nil
      end
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__!(domain_object, table, identifier, entity, context, options) do
      layer = domain_object.__persistence__(:table)[table]
      cond do
        layer == nil -> nil
        layer.type == :mnesia -> nil # structs are not persisted to mnesia, they are embedded in other objects.
        layer.type == :ecto -> domain_object.__as_ecto_record__!(table, identifier, entity, context, options)
        layer.type == :redis -> domain_object.__as_redis_record__!(table, identifier, entity, context, options)
        :else -> nil
      end
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_ecto_record__(domain_object, table, identifier, entity, context, options) do
      context = Noizu.ElixirCore.CallingContext.admin()
      layer = domain_object.__persistence__(:table)[table]
      field_types = domain_object.__noizu_info__(:field_types)
      Enum.map(domain_object.__noizu_info__(:fields) ++ [:identifier],
        fn(field) ->
          cond do
            field == :identifier -> {:identifier, identifier}
            entry = layer.schema_fields[field] ->
              type = field_types[entry[:source]]
              source = case entry[:selector] do
                         nil -> get_in(entity, [Access.key(entry[:source])])
                         path when is_list(path) -> get_in(entity, path)
                         {m,f,a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                         {m,f,a} -> apply(m, f, [entry, entity, a])
                         f when is_function(f, 0) -> f.()
                         f when is_function(f, 1) -> f.(entity)
                         f when is_function(f, 2) -> f.(entry, entity)
                         f when is_function(f, 3) -> f.(entry, entity, context)
                         f when is_function(f, 4) -> f.(entry, entity, context, options)
                       end
              type.handler.cast(entry[:source], entry[:segment], source, type, layer, context, options)
            Map.has_key?(entity, field) -> {field, get_in(entity, [Access.key(field)])}
            :else -> nil
          end
        end)
      |> List.flatten()
      |> Enum.filter(&(&1))
      |> layer.table.__struct__()
    end

    def __as_ecto_record__!(domain_object, table, indexer, ref, context, options) do
      domain_object.__as_ecto_record__(table, indexer, ref, context, options)
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_redis_record__(m, table, indexer, entity, context, options) do
      raise "NYI"
    end

    def __as_redis_record__!(m, table, indexer,  ref, context, options) do
      raise "NYI"
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __from_record__(m, _type, %{entity: temp}, context,  _options) do
      temp
    end
    def __from_record__(m, _type, %{entity: temp}, context,  _options) do
      nil
    end

    def __from_record__!(m, _type, _, context, _options) do
      nil
    end
    def __from_record__(m, _type, _, context,  _options) do
      nil
    end
  end


  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__persistence_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Struct.DefaultPersistenceProvider.Default

      def __as_record__(table, identifier, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_record__(__MODULE__, table, identifier, entity, context, options)
      def __as_record__!(table, identifier, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_record__!(__MODULE__, table, identifier, entity, context, options)
      def __as_ecto_record__(table, identifier, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_ecto_record__(__MODULE__, table, entity, identifier, context, options)
      def __as_ecto_record__!(table, identifier, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_ecto_record__!(__MODULE__, table, entity, identifier, context, options)
      def __as_redis_record__(table, identifier, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_redis_record__(__MODULE__, table, entity, identifier, context, options)
      def __as_redis_record__!(table, identifier, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_redis_record__!(__MODULE__, table, entity, identifier, context, options)
      def __from_record__(type, record, context, options \\ nil), do:  @__nzdo__persistence_imp.__from_record__(__MODULE__, type, record, context, options)
      def __from_record__!(type, record, context, options \\ nil), do:  @__nzdo__persistence_imp.__from_record__!(__MODULE__, type, record, context, options)

      def ecto_entity?(), do: false
      def ecto_identifier(_), do: nil
      def source(_), do: nil
      def universal_identifier(_), do: nil

      defoverridable [
        __as_record__: 4,
        __as_record__: 5,
        __as_record__!: 4,
        __as_record__!: 5,
        __as_ecto_record__: 4,
        __as_ecto_record__: 5,
        __as_ecto_record__!: 4,
        __as_ecto_record__!: 5,
        __as_redis_record__: 4,
        __as_redis_record__: 5,
        __as_redis_record__!: 4,
        __as_redis_record__!: 5,
        __from_record__: 3,
        __from_record__: 4,
        __from_record__!: 3,
        __from_record__!: 4,

        ecto_entity?: 0,
        ecto_identifier: 1,
        source: 1,
        universal_identifier: 1,
      ]
    end
  end

end
