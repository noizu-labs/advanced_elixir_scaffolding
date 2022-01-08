#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.DomainObject.SchemaInfo do
  @moduledoc """
    Provides details about a projects Domain Object Schema, provides sref string ERP support, etc.
  """

  defmodule Behaviour do
    @callback app() :: atom
    @callback base_prefix() :: atom
    @callback database_prefix() ::atom
    @callback module_children(atom) :: list
    @callback __all_properties__() :: map()
    @callback __cache_key__(property :: atom) :: atom
    @callback __valid_table_types__() :: MapSet.t
    @callback __flush__() :: list
    @callback __flush__(p :: list | atom) :: list
    @callback __noizu_info__() :: list | map()
    @callback __noizu_info__(p :: atom) :: any
    @callback info() :: list | map()
    @callback info(p :: atom) :: any
    @callback __nmid_index_list__() :: list
    @callback enums() :: list
    @callback sref_map() :: any
    @callback indexes() :: any
    @callback domain_objects() :: any
    @callback tables() :: any
    @callback meta() :: any
  end

  defmodule Default do
    @moduledoc """
    Default Implementation for the Schema behaviour.
    """

    @doc """
    Return list of modules under `app` that begin with `scope`
    @example ```
    module_children(:my_app, MyApp.Store)
    > [MyApp.Store.Electronics, MyApp.Store.Produce, MyApp.Store.FakeMustaches]
    ```
    """
    def module_children(app, scope) do
      :application.get_key(app, :modules)
      |> elem(1)
      |> Enum.filter(&( List.starts_with?(Module.split(&1),Module.split(scope))))
    end


    def module_children_loaded(app, scope) do
      module_children(app, scope)
      |> Enum.map(fn(m) ->
        Code.ensure_loaded?(m)
        m
      end)
    end

    @doc """
    Return list of Scaffolding modules in `app` starting with `base` whose __noizu_info__(:type) matches the provided `types` filter.
    """
    def filter_modules(app, base, %MapSet{} = types) do
      module_children_loaded(app, base)
      |> Enum.filter(&(function_exported?(&1, :__noizu_info__, 1) && Enum.member?(types, &1.__noizu_info__(:type))))
    end
    def filter_modules(app, base, types) when is_list(types) do
      module_children_loaded(app, base)
      |> Enum.filter(&(function_exported?(&1, :__noizu_info__, 1) && Enum.member?(types, &1.__noizu_info__(:type))))
    end
    def filter_modules(app, base, type) do
      module_children_loaded(app, base)
      |> Enum.filter(&(function_exported?(&1, :__noizu_info__, 1) && &1.__noizu_info__(:type) == type))
    end

    @doc """
       return list of Modules for `app` under `base` prefix of type `type` that match the user provided `filter` method.
    """
    def filter_modules(app, base, type, filter) do
      filter_modules(app, base, type)
      |> Enum.filter(fn(entry) -> filter.(entry) end)
    end


    @doc """
      cache wrapper for filter_modules/2
    """
    def cached_filter(key, app, base) do
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = module_children_loaded(app, base)
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
      end
    end

    @doc """
      cache wrapper for filter_modules/3
    """
    def cached_filter(key, app, base, type) do
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = filter_modules(app, base, type)
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
      end
    end

    @doc """
    cache wrapper for filter_modules/4
    """
    def cached_filter(key, app, base, type, filter) do
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = filter_modules(app, base, type, filter)
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
      end
    end

    @doc """
    Parse `sref` and return it's ref tuple or an Noizu.DomainObject.UnsupportedModule.ref if `sref` is correctly formatted but no handler is found in the sref_map() set.
    @example ```
      parse_sref(MyApp.ScaffoldingSchema, "ref.foo-bar.1234") -> {:ref, MyApp.FooBar.Entity, 1234}
      parse_sref(MyApp.ScaffoldingSchema, "ref.foo-not-found.1234") -> throw "UnsupportedModule ref.foo-not-found.1234"
      parse_sref(MyApp.ScaffoldingSchema, "ref.bar[ref.foo-bar.1234, ref.user.noizu]") -> {:ref, MyApp.Bar.Entity, [{:ref, MyApp.FooBar.Entity, 1234}, {:ref, MyApp.User.Entity, :noizu}]
      parse_sref(MyApp.ScaffoldingSchema, "ref.cms{1234-1.1.3@3}") -> {:ref, MyApp.CMS.Entity, {{:article, 1234}, {:version, {1,1,3}, {:revision, 3}}}
    ```
    """
    def parse_sref(mod, sref) do
      cond do
        Regex.match?(~r/^ref\.([^.]*)\.(.*)$/, sref) ->
          [_p, m_str, _id_str| _] = Regex.run(~r/^ref\.([^.]*)\.(.*)$/, sref)
          m = mod.sref_map()[m_str] || Noizu.DomainObject.UnsupportedModule
          m.ref(sref)
        Regex.match?(~r/^ref\.([^.\[\{]*)\[(.*)\]$/, sref) ->
          [_p, m_str, _id_str| _] = Regex.run(~r/^ref\.([^.\[\{]*)\[(.*)\]$/, sref)
          m = mod.sref_map()[m_str] || Noizu.DomainObject.UnsupportedModule
          m.ref(sref)
        Regex.match?(~r/^ref\.([^.\[\{]*)\{(.*)\}$/, sref) ->
          [_p, m_str, _id_str| _] = Regex.run(~r/^ref\.([^.\[\{]*)\{(.*)\}$/, sref)
          m = mod.sref_map()[m_str] || Noizu.DomainObject.UnsupportedModule
          m.ref(sref)
        :else -> nil
      end
    end

    @doc """
      Return Map of Scaffolding Configuration Property Details
    """
    def __noizu_info__(m) do
      key = m.__cache_key__(:all)
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = Enum.map(m.__all_properties__() -- [:all], &({&1, m.__noizu_info__(&1)}))
                  |> Map.new
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
      end
    end

    @doc """
      Scaffolding Configuration Property Details (:type, :nmid_indexes, :indexes, :enums, :tables, :sref_map, ...)
    """
    def __noizu_info__(_m, :type), do: :schema
    def __noizu_info__(m, :nmid_indexes), do: m.__nmid_index_list__()
    def __noizu_info__(m, :entities = property), do: cached_filter(m.__cache_key__(property), m.app(), m.base_prefix(), :entity)
    def __noizu_info__(m, :indexes = property), do: cached_filter(m.__cache_key__(property), m.app(), m.base_prefix(), :index)
    def __noizu_info__(m, :enums = property), do: cached_filter(m.__cache_key__(property), m.app(), m.base_prefix(), :entity, &(&1.__noizu_info__(:meta)[:enum_entity]))
    def __noizu_info__(m, :tables = property), do: cached_filter(m.__cache_key__(property), m.app(), m.database_prefix(), m.__valid_table_types__())
    def __noizu_info__(m, :sref_map = property) do
      key = m.__cache_key__(property)
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = Enum.map(m.__noizu_info__(:entities), &({&1.__noizu_info__(:sref), &1})) |> Map.new()
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
      end
    end
    def __noizu_info__(m, :meta = property) do
      key = m.__cache_key__(property)
      case FastGlobal.get(key, :cache_miss) do
        :cache_miss ->
          cache = Enum.map(m.__noizu_info__(:entities), &({&1, &1.__noizu_info__(:meta)})) |> Map.new()
          FastGlobal.put(key, cache)
          cache
        cache_hit -> cache_hit
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

  #--------------------------------------------
  # __noizu_schema_info__
  #--------------------------------------------
  @doc """
    Returns Scaffolding Schema implementation.
  """
  def __noizu_schema_info__(caller, options, block) do
    base_prefix = options[:base_prefix] || :auto
    database_prefix = options[:database_prefix] || :auto
    Noizu.AdvancedScaffolding.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider
    scaffolding_schema_provider = options[:scaffolding_schema_implementation] || Noizu.DomainObject.SchemaInfo.Default
    app = options[:app] || throw "You must pass noizu_scaffolding_schema(app: :your_app)"
    s1 = quote do
           @behaviour Noizu.DomainObject.SchemaInfo.Behaviour
           require Noizu.DomainObject
           require Noizu.AdvancedScaffolding.Internal.Helpers
           require Noizu.DomainObject.SchemaInfo
           import Noizu.ElixirCore.Guards
           @options unquote(options)
           @app unquote(app)
           @base_prefix (case unquote(base_prefix) do
                           :auto -> Module.concat([List.first(Module.split(__MODULE__))])
                           v -> v
                         end)
           @database_prefix (case unquote(database_prefix) do
                               :auto ->
                                 __MODULE__
                                 |> Noizu.AdvancedScaffolding.Schema.PersistenceSettings.__default_ecto_repo__()
                                 |> Module.split()
                                 |> Enum.slice(0..-2)
                                 |> Module.concat()
                               v -> v
                             end)

           #---------------------
           # Insure Single Call
           #---------------------
           @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
           Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__scaffolding_defined, unquote(caller))

           Module.register_attribute(__MODULE__, :cache_keys, accumulate: false)

           #----------------------
           # User block section (define, fields, constraints, json_mapping rules, etc.)
           #----------------------
           @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
           try do
             # we rely on the same providers as used in the Entity type for providing json encoding, restrictions, etc.
             import Noizu.DomainObject.SchemaInfo
             @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
             unquote(block)
           after
             :ok
           end

           :ok
         end


    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(s1)



      @__nzdo__internal_imp unquote(scaffolding_schema_provider)
      @valid_table_types MapSet.new(Module.get_attribute(__MODULE__, :valid_table_types) || [:table, :entity_table, :enum_table])
      @cache_keys Map.merge(@cache_keys || %{}, %{
        type: :"__nzss__#{@app}__type",
        all: :"__nzss__#{@app}__*",
        nmid_indexes: :"__nzss__#{@app}__nmid_indexes",
        entities: :"__nzss__#{@app}__entities",
        indexes: :"__nzss__#{@app}__indexes",
        enums: :"__nzss__#{@app}__enums",
        tables: :"__nzss__#{@app}__tables",
        sref_map: :"__nzss__#{@app}__sref_map",
        meta: :"__nzss__#{@app}__meta",
      })
      @all_properties Map.keys(@cache_keys)


      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Application App
      """
      def app(), do: @app

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Base Application Module
      """
      def base_prefix(), do: @base_prefix

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Ecto Database Base Module (e.g. YourApplicationSchema.MySQL)
      """
      def database_prefix(), do: @database_prefix

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Return modules in application starting with scope Module.
      @example ```
      module_children(MyApp.Foo)
      > [ MyApp.Foo,Bar, MyApp.Foo.Bop ]
      ```
      """
      def module_children(scope), do: @__nzdo__internal_imp.module_children(@app, scope)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        All properties the scaffolding schema module provides in its __noizu_info__/1 method.
      """
      def __all_properties__(), do: @all_properties

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        FastGlobal cache key used to store results for given property.
      """
      def __cache_key__(property), do: @cache_keys[property]

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
        List of table identifiers (e.g. used to filter entities whose __noizu_info__(:type) value is in the set of table types).
      """
      def __valid_table_types__(), do: @valid_table_types

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Flush all cached property values (e.g. __noizu_info__(p) runtime computed values)
      """
      def __flush__(), do: __flush__(__all_properties__())
      @doc """
      Flush cache for __noizu_info__(property).
      """
      def __flush__(property) when is_atom(property), do: __flush__([property])
      def __flush__(properties) when is_list(properties) do
        Enum.map(properties ++ [:all], fn(property) ->
          if key = __cache_key__(property) do
            FastGlobal.delete(key)
          end
        end)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Return all DomainObject configuration settings.
      """
      def __noizu_info__(), do: @__nzdo__internal_imp.__noizu_info__(__MODULE__)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Return specific configuration property. (:entities, :tables, ...)
      """
      def __noizu_info__(property), do: @__nzdo__internal_imp.__noizu_info__(__MODULE__, property)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      alias of __noizu_info__/0
      """
      def info(), do: __noizu_info__()
      @doc """
      alias of __noizu_info__/1
      """
      def info(property), do: __noizu_info__(property)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Return keyword list of entities/tables and their nmid identifier code.
      """
      def __nmid_index_list__(), do: []

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Alias for __noizu_info__(:enums), returns set of all Enum DomainObjects in App.
      """
      def enums(), do: __noizu_info__(:enums)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Alias for __noizu_info__(:sref_map), returns map sref prefixes and their associated DomainObject.Entity
      """
      def sref_map(), do: __noizu_info__(:sref_map)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Alias for __noizu_info__(:indexes), returns list of DomainObject.Index search index modules. (E.g. MyApp.User.Index, MyApp.Post.Index)
      """
      def indexes(), do: __noizu_info__(:indexes)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Alias for __noizu_info__(:entities), returns list of DomainObject.Entities. (E.g. MyApp.User.Entity, MyApp.Post.Entity)
      """
      def domain_objects(), do: __noizu_info__(:entities)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Alias for __noizu_info__(:tables), returns list of table modules. (E.g. MyAppSchema.MySQL.User.Table)
      """
      def tables(), do: __noizu_info__(:tables)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Alias for __noizu_info__(:meta), returns map of DomainObject.Entity => DomainObject.Entity.__noizu_info__(:meta)
      """
      def meta(), do: __noizu_info__(:meta)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Returns ref tuple for a sref string if there is a matching DomainObject.Entity handler defined in the __noizu_info__(:sref_map) set.
      """
      def parse_sref(sref), do: @__nzdo__internal_imp.parse_sref(__MODULE__, sref)

      defoverridable [
        app: 0,
        base_prefix: 0,
        database_prefix: 0,
        __valid_table_types__: 0,
        __all_properties__: 0,
        __cache_key__: 1,
        __flush__: 0,
        __flush__: 1,
        __noizu_info__: 0,
        __noizu_info__: 1,
        __nmid_index_list__: 0,
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


      #----------------------------
      # Before/After Compile
      #----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @before_compile unquote(scaffolding_schema_provider)
      @after_compile unquote(scaffolding_schema_provider)
      @file __ENV__.file
    end
  end




end
