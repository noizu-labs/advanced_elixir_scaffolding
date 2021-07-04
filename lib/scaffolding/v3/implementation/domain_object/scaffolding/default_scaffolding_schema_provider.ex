defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider do

  defmodule Default do

    def module_children(app, scope) do
      :application.get_key(app, :modules)
      |> elem(1)
      |> Enum.filter(&( List.starts_with?(Module.split(&1),Module.split(scope))))
    end


    def filter_modules(app, base, %MapSet{} = types) do
      module_children(app, base)
      |> Enum.filter(&(function_exported?(&1, :__noizu_info__, 1) && Enum.member?(types, &1.__noizu_info__(:type))))
    end
    def filter_modules(app, base, types) when is_list(types) do
      module_children(app, base)
      |> Enum.filter(&(function_exported?(&1, :__noizu_info__, 1) && Enum.member?(types, &1.__noizu_info__(:type))))
    end
    def filter_modules(app, base, type) do
      module_children(app, base)
      |> Enum.filter(&(function_exported?(&1, :__noizu_info__, 1) && &1.__noizu_info__(:type) == type))
    end

    def cached_filter(key, app, base, type) do
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = filter_modules(app, base, type)
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
      end
    end


    def cached_filter(key, app, base, type, filter) do
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = filter_modules(app, base, type)
                  |> Enum.filter(fn(entry) -> filter.(entry) end)
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
      end
    end

  end

  defmacro __using__(_options \\ nil) do
    quote do
      # We forward down tot he entity profider's implementations
      @__nzdo__internal_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider.Default
      @valid_table_types MapSet.new(Module.get_attribute(__MODULE__, :valid_table_types) || [:table, :entity_table, :enum_table])

      @cache_keys Map.merge(@cache_keys || %{}, %{
        type: :"__nzss__#{@app}__type",
        all: :"__nzss__#{@app}__*",
        entities: :"__nzss__#{@app}__entities",
        indexes: :"__nzss__#{@app}__indexes",
        enums: :"__nzss__#{@app}__enums",
        tables: :"__nzss__#{@app}__tables",
        sref_map: :"__nzss__#{@app}__sref_map",
        meta: :"__nzss__#{@app}__meta",
      })
      @all_properties Map.keys(@cache_keys)


      Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider.Default

      def module_children(scope), do: @__nzdo__internal_imp.module_children(@app, scope)

      def __all_properties__(), do: @all_properties

      def __cache_key__(property), do: @cache_keys[property]

      def __valid_table_types__(), do: @valid_table_types

      def __flush__(), do: __flush__(__all_properties__())
      def __flush__(property) when is_atom(property), do: __flush__([property])
      def __flush__(properties) when is_list(properties) do
        Enum.map(properties ++ :all, fn(property) ->
          if key = __cache_key__(property) do
            FastGlobal.delete(key)
          end
        end)
      end

      def __noizu_info__() do
        key = __cache_key__(:all)
        case FastGlobal.get(key, :cache_miss) do
          :cache_miss ->
            cache = Enum.map(__all_properties__() -- [:all], &({&1, __noizu_info__(&1)}))
                    |> Map.new
            FastGlobal.put(key, cache)
            cache
          cache_hit -> cache_hit
        end
      end

      def __noizu_info__(:type), do: :schema
      def __noizu_info__(:entities = property), do: @__nzdo__internal_imp.cached_filter(__cache_key__(property), @app, @base_prefix, :entity)
      def __noizu_info__(:indexes = property), do: @__nzdo__internal_imp.cached_filter(__cache_key__(property), @app, @base_prefix, :index)
      def __noizu_info__(:enums = property), do: @__nzdo__internal_imp.cached_filter(__cache_key__(property), @app, @base_prefix, :entity, &(&1.__noizu_info__(:meta)[:enum_entity]))
      def __noizu_info__(:tables = property), do: @__nzdo__internal_imp.cached_filter(__cache_key__(property), @app, @database_prefix, __valid_table_types__())
      def __noizu_info__(:sref_map = property) do
        key = __cache_key__(property)
        case FastGlobal.get(key, :cache_miss) do
          :cache_miss ->
            cache = Enum.map(__noizu_info__(:entities), &({&1.__noizu_info__(:sref), &1})) |> Map.new()
            FastGlobal.put(key, cache)
            cache
          cache_hit -> cache_hit
        end
      end
      def __noizu_info__(:meta = property) do
        key = __cache_key__(property)
        case FastGlobal.get(key, :cache_miss) do
          :cache_miss ->
            cache = Enum.map(__noizu_info__(:entities), &({&1, &1.__noizu_info__(:meta)})) |> Map.new()
            FastGlobal.put(key, cache)
            cache
          cache_hit -> cache_hit
        end
      end

      def info(), do: __noizu_info__()
      def info(property), do: __noizu_info__(property)

      def enums(), do: __noizu_info__(:enums)
      def sref_map(), do: __noizu_info__(:sref_map)
      def indexes(), do: __noizu_info__(:indexes)
      def domain_objects(), do: __noizu_info__(:entities)
      def tables(), do: __noizu_info__(:tables)
      def meta(), do: __noizu_info__(:meta)

      def parse_sref(sref) do
        cond do
          Regex.match?(~r/^ref\.([^.]*)\.(.*)$/, sref) ->
            [_p, m_str, id_str| _] = Regex.run(~r/^ref\.([^.]*)\.(.*)$/, sref)
            m = sref_map()[m_str] || Noizu.Scaffolding.UnsupportedModule
            m.ref(id_str)
          Regex.match?(~r/^ref\.([^.\[\{]*)\[(.*)\]$/, sref) ->
            [_p, m_str, id_str| _] = Regex.run(~r/^ref\.([^.\[\{]*)\[(.*)\]$/, sref)
            m = sref_map()[m_str] || Noizu.Scaffolding.UnsupportedModule
            m.ref(id_str)
          Regex.match?(~r/^ref\.([^.\[\{]*)\{(.*)\}$/, sref) ->
            [_p, m_str, id_str| _] = Regex.run(~r/^ref\.([^.\[\{]*)\{(.*)\}$/, sref)
            m = sref_map()[m_str] || Noizu.Scaffolding.UnsupportedModule
            m.ref(id_str)
          :else -> nil
        end
      end

      defoverridable [
        __valid_table_types__: 0,
        __all_properties__: 0,
        __cache_key__: 1,
        __flush__: 0,
        __flush__: 1,
        __noizu_info__: 0,
        __noizu_info__: 1,
        info: 0,
        info: 1,
        enums: 0,
        sref_map: 0,
        indexes: 0,
        domain_objects: 0,
        tables: 0,
        meta: 0,
        parse_sref: 1,
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
