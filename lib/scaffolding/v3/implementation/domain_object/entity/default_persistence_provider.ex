defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultPersistenceProvider do

  defmodule Default do
    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__(domain_object, table, ref, context, options) do
      cond do
        entity = domain_object.entity(ref, options) ->
          layer = domain_object.__persistence__(:table)[table]
          cond do
            layer == nil -> throw "#{domain_object}.__as_record__ to table #{inspect table} not supported"
            layer.type == :mnesia -> domain_object.__as_mnesia_record__(table, entity, context, options)
            layer.type == :ecto -> domain_object.__as_ecto_record__(table, entity, context, options)
            layer.type == :redis -> domain_object.__as_redis_record__(table, entity, context, options)
            layer.type != domain_object && Kernel.function_exported?(layer.type, :__as_record__, 4) -> layer.type.__as_record__(table, entity, context, options)
            :else -> throw "#{domain_object}.__as_record__ layer.type (#{inspect layer.type}) not supported"
          end
        :else -> nil
      end
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_record__!(domain_object, table, ref, context, options) do
      cond do
        entity = domain_object.entity!(ref, options) ->
          layer = domain_object.__persistence__(:table)[table]
          cond do
            layer == nil -> throw "#{domain_object}.__as_record__! to table #{inspect table} not supported"
            layer.type == :mnesia -> domain_object.__as_mnesia_record__!(table, entity, context, options)
            layer.type == :ecto -> domain_object.__as_ecto_record__!(table, entity, context, options)
            layer.type == :redis -> domain_object.__as_redis_record__!(table, entity, context, options)
            layer.type != domain_object && Kernel.function_exported?(layer.type, :__as_record__!, 4) -> layer.type.__as_record__!(table, entity, context, options)
            :else -> throw "#{domain_object}.__as_record__! layer.type (#{inspect layer.type}) not supported"
          end
        :else -> nil
      end
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_mnesia_record__(domain_object, table, entity, context, options) do
      context = Noizu.ElixirCore.CallingContext.system(context)
      layer = domain_object.__persistence__(:table)[table]
      field_types = domain_object.__noizu_info__(:field_types)
      fields = Map.keys(table.__struct__([]))  -- [:__struct__, :__meta__]
      Enum.map(fields,
        fn(field) ->
          cond do
            field == :entity -> entity
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

    def __as_mnesia_record__!(domain_object, table, ref, context, options) do
      domain_object.__as_mnesia_record__(table, ref, context, options)
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_ecto_record__(domain_object, table, entity, context, options) do
      context = Noizu.ElixirCore.CallingContext.admin()
      layer = domain_object.__persistence__(:table)[table]
      field_types = domain_object.__noizu_info__(:field_types)
      Enum.map(domain_object.__noizu_info__(:fields),
        fn(field) ->
          cond do
            field == :identifier -> {:identifier, Noizu.Ecto.Entity.ecto_identifier(entity)}
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

    def __as_ecto_record__!(domain_object, table, ref, context, options) do
      domain_object.__as_ecto_record__(table, ref, context, options)
    end

    #-----------------------------------
    #
    #-----------------------------------
    def __as_redis_record__(m, table, entity, context, options) do
      raise "NYI"
    end

    def __as_redis_record__!(m, table, ref, context, options) do
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


    def ecto_identifier(_, %{ecto_identifier: id}), do: id
    def ecto_identifier(_, %{identifier: id}) when is_integer(id), do: id
    def ecto_identifier(m, ref) do
      ref = m.ref(ref)
      case Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable.read!(ref) do
        %Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable{ecto_identifier: id} -> id
        _ ->
          case m.entity(ref) do
            %{ecto_identifier: id} ->
              Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable.write!(%Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable{identifier: ref, ecto_identifier: id})
              id
            _ -> nil
          end
      end
    end

    def universal_identifier_lookup(m, ref) do
      ref = m.ref(ref)
      case Noizu.Scaffolding.V3.Database.UniversalLookupTable.read!(ref) do
        %Noizu.Scaffolding.V3.Database.UniversalLookupTable{universal_identifier: id} -> id
      end
    end

  end


  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__persistence_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultPersistenceProvider.Default

      def __as_record__(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_record__(__MODULE__, table, entity, context, options)
      def __as_record__!(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_record__!(__MODULE__, table, entity, context, options)
      def __as_mnesia_record__(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_mnesia_record__(__MODULE__, table, entity, context, options)
      def __as_mnesia_record__!(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_mnesia_record__!(__MODULE__, table, entity, context, options)
      def __as_ecto_record__(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_ecto_record__(__MODULE__, table, entity, context, options)
      def __as_ecto_record__!(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_ecto_record__!(__MODULE__, table, entity, context, options)

      def __as_redis_record__(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_redis_record__(__MODULE__, table, entity, context, options)
      def __as_redis_record__!(table, entity, context, options \\ nil), do:  @__nzdo__persistence_imp.__as_redis_record__!(__MODULE__, table, entity, context, options)

      def __from_record__(type, record, context, options \\ nil), do:  @__nzdo__persistence_imp.__from_record__(__MODULE__, type, record, context, options)
      def __from_record__!(type, record, context, options \\ nil), do:  @__nzdo__persistence_imp.__from_record__!(__MODULE__, type, record, context, options)

      if (@__nzdo_persistence.ecto_entity) do
        def ecto_entity?(), do: true
        cond do
          Module.has_attribute?(__MODULE__, :__nzdo__ecto_identifier_field) -> def ecto_identifier(ref), do: @__nzdo__persistence_imp.ecto_identifier(__MODULE__, ref)
          Module.get_attribute(__MODULE__, :__nzdo__identifier_type) == :integer -> def ecto_identifier(ref), do: __MODULE__.id(ref)
          :else -> def ecto_identifier(_), do: raise "Not Supported"
        end
        def source(_), do: @__nzdo_persistence.ecto_entity
        cond do
          @__nzdo_persistence.options[:universal_identifier] -> def universal_identifier(ref), do: __MODULE__.id(ref)
          @__nzdo_persistence.options[:universal_lookup] -> def universal_identifier(ref), do: @__nzdo__persistence_imp.universal_identifier_lookup(__MODULE__, ref)
          :else -> def universal_identifier(_), do: raise "Not Supported"
        end
      else
        def ecto_entity?(), do: false
        def ecto_identifier(_), do: nil
        def source(_), do: nil
        def universal_identifier(_), do: nil
      end

      defoverridable [
        __as_record__: 3,
        __as_record__: 4,
        __as_record__!: 3,
        __as_record__!: 4,
        __as_mnesia_record__: 3,
        __as_mnesia_record__: 4,
        __as_mnesia_record__!: 3,
        __as_mnesia_record__!: 4,
        __as_ecto_record__: 3,
        __as_ecto_record__: 4,
        __as_ecto_record__!: 3,
        __as_ecto_record__!: 4,
        __as_redis_record__: 3,
        __as_redis_record__: 4,
        __as_redis_record__!: 3,
        __as_redis_record__!: 4,
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
