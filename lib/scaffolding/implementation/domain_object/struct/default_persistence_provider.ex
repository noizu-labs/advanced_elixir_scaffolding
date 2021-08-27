defmodule Noizu.AdvancedScaffolding.Implementation.DomainObject.Struct.DefaultPersistenceProvider do

  defmodule Default do
    alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__(domain_object, %PersistenceLayer{} = layer, identifier, entity, context, options) do
      domain_object.__as_record_type__(layer, identifier, entity, context, options)
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__!(domain_object, %PersistenceLayer{} = layer, identifier, entity, context, options) do
      domain_object.__as_record_type__!(layer, identifier, entity, context, options)
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_record_type__(domain_object, %PersistenceLayer{type: :ecto} = layer, identifier, entity, context, options) do
      context = Noizu.ElixirCore.CallingContext.system(context)
      field_types = domain_object.__noizu_info__(:field_types)
      Enum.map(
        domain_object.__noizu_info__(:fields) ++ [:identifier],
        fn (field) ->
          cond do
            field == :identifier -> {:identifier, identifier}
            entry = layer.schema_fields[field] ->
              type = field_types[entry[:source]]
              source = case entry[:selector] do
                         nil -> get_in(entity, [Access.key(entry[:source])])
                         path when is_list(path) -> get_in(entity, path)
                         {m, f, a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                         {m, f, a} -> apply(m, f, [entry, entity, a])
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
        end
      )
      |> List.flatten()
      |> Enum.filter(&(&1))
      |> layer.table.__struct__()
    end

    def __as_record_type__(_domain_object, %PersistenceLayer{} = _layer, _identifier, _entity, _context, _options), do: nil

    def __as_record_type__!(domain_object, layer, identifier, entity, context, options), do: domain_object.__as_record_type__(layer, identifier, entity, context, options)

    #-----------------------------------
    #
    #-----------------------------------
    def __from_record__(_m, %PersistenceLayer{} = _layer, %{entity: temp}, _context, _options), do: temp
    def __from_record__(_m, %PersistenceLayer{} = _layer, _ref, _context, _options), do: nil

    def __from_record__!(_m, %PersistenceLayer{} = _layer, %{entity: temp}, _context, _options), do: temp
    def __from_record__!(_m, %PersistenceLayer{} = _layer, _ref, _context, _options), do: nil
  end


  defmacro __using__(_options \\ nil) do
    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
      @__nzdo__persistence_imp Noizu.AdvancedScaffolding.Implementation.DomainObject.Struct.DefaultPersistenceProvider.Default

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __as_record__(%PersistenceLayer{} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record__(__MODULE__, layer, identifier, entity, context, options)
      def __as_record__!(%PersistenceLayer{} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record__!(__MODULE__, layer, identifier, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __as_record_type__(%PersistenceLayer{} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record_type__(__MODULE__, layer, identifier, entity, context, options)
      def __as_record_type__!(%PersistenceLayer{} = layer, identifier, entity, context, options \\ nil),
          do: @__nzdo__persistence_imp.__as_record_type__!(__MODULE__, layer, identifier, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __from_record__(%PersistenceLayer{} = layer, record, context, options \\ nil), do: @__nzdo__persistence_imp.__from_record__(__MODULE__, layer, record, context, options)
      def __from_record__!(%PersistenceLayer{} = layer, record, context, options \\ nil), do: @__nzdo__persistence_imp.__from_record__!(__MODULE__, layer, record, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def ecto_entity?(), do: false
      def ecto_identifier(_), do: nil
      def source(_), do: nil
      def universal_identifier(_), do: nil

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        __as_record__: 4,
        __as_record__: 5,
        __as_record__!: 4,
        __as_record__!: 5,
        __as_record_type__: 4,
        __as_record_type__: 5,
        __as_record_type__!: 4,
        __as_record_type__!: 5,
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
