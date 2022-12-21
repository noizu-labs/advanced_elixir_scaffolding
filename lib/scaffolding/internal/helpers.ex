#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Helpers do
  
  
  
  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __transaction_block__(_options \\ [], [do: block]) do
    quote do
      #@file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      case @__nzdo_top_layer_tx_block do
        :none ->
          unquote(block)
        :tx ->
          Amnesia.transaction do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :async ->
          Amnesia.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :sync ->
          Amnesia.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_tx ->
          Amnesia.Fragment.transaction do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_async ->
          Amnesia.Fragment.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_sync ->
          Amnesia.Fragment.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        _ ->
          unquote(block)
      end
    end
  end
  
  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __layer_transaction_block__(layer, options \\ [], [do: block]) do
    Noizu.AdvancedScaffolding.Internal.Helpers.__layer_transaction_block__d(__CALLER__, layer, options, block)
  end
  
  #--------------------------------------------
  #
  #--------------------------------------------
  def __layer_transaction_block__d(_caller, layer, _options, block) do
    quote do
      #@file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      case is_map(unquote(layer)) && unquote(layer).tx_block do
        :none ->
          unquote(block)
        :tx ->
          Amnesia.transaction do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :async ->
          Amnesia.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :sync ->
          Amnesia.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_tx ->
          Amnesia.Fragment.transaction do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_async ->
          Amnesia.Fragment.async do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        :fragment_sync ->
          Amnesia.Fragment.sync do
            try do
              unquote(block)
            rescue e ->
              Logger.error("TXN #{__MODULE__} - rescue #{Exception.format(:error, e, __STACKTRACE__)}")
            catch
              :exit, e ->
                Logger.error("TXN #{__MODULE__} - exit #{Exception.format(:error, e, __STACKTRACE__)}")
              e ->
                Logger.error("TXN #{__MODULE__} - catch #{Exception.format(:error, e, __STACKTRACE__)}")
            end
          end
        _ ->
          unquote(block)
      end
    end
  end
  
  
  
  @doc """
  Load settings for SimpleObject from passed in options, inline @attributes and its base module's attributes or config methods (if already compiled)
  """
  defmacro __prepare_simple_object__(options) do
    quote do

      # Extract Base Fields fields since SimbpleObjects are at the same level as their base.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @simple_object __MODULE__
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__base__macro__(unquote(options))

      # Push details to Base, and read in required settings.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__poly__macro__(unquote(options))

      # Load Sphinx Settings from base.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__sphinx__macro__(unquote(options))

      # Load Persistence Settings from base, we need them to control some submodules.
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__persistence_settings__macro__(unquote(options))

      # Nmid
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__nmid__macro__(unquote(options))

      # Json Settings
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__json_settings__macro__(unquote(options))

    end
  end



  @doc """
  Insure macro/use is only called once.
  """
  defmacro insure_single_use(type, caller) do
    quote do
      relative_file = Noizu.AdvancedScaffolding.Internal.Helpers.file_rel_dir(unquote(caller.file))
      if line = Module.get_attribute(__MODULE__, unquote(type)) do
        raise "#{relative_file}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.#{unquote(__CALLER__.function)} first defined on #{elem(line, 0)}:#{elem(line, 1)}"
      end
      Module.put_attribute(__MODULE__, unquote(type), {relative_file, unquote(caller.line)})
    end
  end

  #----------------------------------------------------
  # __prepare__base__macro__
  #----------------------------------------------------
  defmacro __prepare__base__macro__(options) do
    quote do
      base = unquote(options)[:base]

      @__nzdo__base base || Module.get_attribute(__MODULE__, :simple_object) || (
        Module.split(__MODULE__)
        |> Enum.slice(0..-2)
        |> Module.concat())
      @__nzdo__base_open? Module.open?(@__nzdo__base)
      @base_meta ((Module.has_attribute?(@__nzdo__base, :meta) && Module.get_attribute(@__nzdo__base, :meta) || []))
      Module.delete_attribute(__MODULE__, :meta)
      Module.register_attribute(__MODULE__, :meta, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__derive, accumulate: true)


      Module.register_attribute(__MODULE__, :__nzdo__entity, accumulate: false)
      Module.register_attribute(__MODULE__, :__nzdo__struct, accumulate: false)

      if @__nzdo__base_open? && !(Module.get_attribute(@__nzdo__base, :__nzdo__base_defined) || Module.get_attribute(@__nzdo__base, :__nzdo__simple_defined))do
        raise "#{@__nzdo__base} must include use Noizu.SimpleObject/DomainObject call."
      end
    end
  end



  #----------------------------------------------------
  # __prepare__poly__macro__
  #----------------------------------------------------
  defmacro __prepare__poly__macro__(options) do
    quote do
      options = unquote(options)
      noizu_domain_object_schema = options[:noizu_domain_object_schema] || Application.get_env(:noizu_advanced_scaffolding, :domain_object_schema)
      poly_base = options[:poly_base]
      poly_support = options[:poly_support]
      repo = options[:repo]
      vsn = options[:vsn]
      sref = options[:sref]
      kind = options[:kind]


      entity = cond do
                 options[:for_repo] ->
                   entity = Module.concat(Enum.slice(Module.split(__MODULE__), 0..-2) ++ [Entity])
                   Module.put_attribute(__MODULE__, :__nzdo__entity, entity)
                   Module.put_attribute(__MODULE__, :__nzdo__struct, entity)
                 :else ->
                   Module.put_attribute(__MODULE__, :__nzdo__entity, __MODULE__)
                   Module.put_attribute(__MODULE__, :__nzdo__struct, __MODULE__)
               end

      @__nzdo__schema_helper noizu_domain_object_schema
      @__nzdo__poly_base (cond do
                            v = poly_base -> v
                            v = Module.get_attribute(__MODULE__, :poly_base) -> v
                            !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(:poly_base) -> @__nzdo__base.__noizu_info__(:poly_base)
                            @__nzdo__base_open? -> (Module.get_attribute(@__nzdo__base, :poly_base) || @__nzdo__base)
                            :else -> @__nzdo__base
                          end)

      @__nzdo__poly_base_open? Module.open?(@__nzdo__poly_base)
      @__nzdo__poly_support (cond do
                               poly_support -> poly_support
                               v = Module.get_attribute(__MODULE__, :poly_support) -> v
                               v = @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, :poly_support) -> v
                               v = !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(:poly)[:support] -> v
                               v = @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, :poly_support) -> v
                               v = !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(:poly)[:support] -> v
                               :else -> nil
                             end)
      @__nzdo__poly_support is_list(@__nzdo__poly_support) && List.flatten(@__nzdo__poly_support) || @__nzdo__poly_support
      @__nzdo__poly? ((@__nzdo__poly_base != @__nzdo__base || @__nzdo__poly_support) && true || false)
      @__nzdo__repo repo || Noizu.AdvancedScaffolding.Internal.Helpers.extract_attribute(:repo, Module.concat([@__nzdo__poly_base, "Repo"]))
      @__nzdo__sref sref || Noizu.AdvancedScaffolding.Internal.Helpers.extract_attribute(:sref, :unsupported)
      @__nzdo__kind kind || Noizu.AdvancedScaffolding.Internal.Helpers.extract_attribute(:kind, @__nzdo__sref)
      @vsn vsn || Noizu.AdvancedScaffolding.Internal.Helpers.extract_attribute(:vsn, 1.0)

      if @__nzdo__base_open? && !options[:for_repo] do
        Module.put_attribute(@__nzdo__base, :__nzdo__sref, @__nzdo__sref)
        Module.put_attribute(@__nzdo__base, :__nzdo__kind, @__nzdo__kind)
        Module.put_attribute(@__nzdo__base, :__nzdo__entity, __MODULE__)
        Module.put_attribute(@__nzdo__base, :__nzdo__struct, __MODULE__)
        Module.put_attribute(@__nzdo__base, :__nzdo__poly_support, @__nzdo__poly_support)
        Module.put_attribute(@__nzdo__base, :__nzdo__poly?, @__nzdo__poly?)
        Module.put_attribute(@__nzdo__base, :__nzdo__poly_base, @__nzdo__poly_base)
        Module.put_attribute(@__nzdo__base, :vsn, @vsn)
      end
    end
  end

  #----------------------------------------------------
  # __prepare__sphinx__macro__
  #----------------------------------------------------
  defmacro __prepare__sphinx__macro__(options) do
    quote do
      options = unquote(options)

      #----------------------
      # Load Sphinx Settings from base.
      #----------------------
      @__nzdo__indexes Noizu.AdvancedScaffolding.Internal.Helpers.extract_transform_attribute(:index, :indexing, {Noizu.AdvancedScaffolding.Internal.DomainObject.Index.Default, :__expand_indexes__, [@__nzdo__base]}, [])
      @__nzdo__index_list Enum.map(@__nzdo__indexes, fn ({k, _v}) -> k end)
      index_mod = Noizu.AdvancedScaffolding.Internal.DomainObject.Index.Default.__domain_object_indexer__(@__nzdo__base)
      index_mod = cond do
                    @__nzdo__indexes[index_mod] -> index_mod
                    :else -> false
                  end
      #IO.puts "#{__MODULE__}:: CHECK #{inspect @__nzdo__indexes[index_mod]} ... #{inspect index_mod}"
      @__nzdo__inline_index index_mod

      if (@__nzdo__base_open? && !options[:for_repo]) do
        Module.put_attribute(@__nzdo__base, :__nzdo__indexes, @__nzdo__indexes)
        Module.put_attribute(@__nzdo__base, :__nzdo__index_list, @__nzdo__index_list)
        Module.put_attribute(@__nzdo__base, :__nzdo__inline_index, @__nzdo__inline_index)
      end
    end
  end

  #----------------------------------------------------
  # __prepare__persistence_settings__macro__
  #----------------------------------------------------
  defmacro __prepare__persistence_settings__macro__(options) do
    enum_list = options[:enum_list]
    quote do
      options = unquote(options)

      a__nzdo__auto_generate = Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_persistence_attribute(:auto_generate, nil)
      a__nzdo__enum_list = unquote(enum_list) || Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_enum_attribute(:enum_list, :list, false)
      a__nzdo__enum_default_value  = Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_enum_attribute(:default_value, :default, :none)
      a__nzdo__enum_ecto_type = Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_enum_attribute(:ecto_type, :value_type, :integer)

      # @todo unified attribute  @cache :fast_global, schema: :default, prime: true, ttl: 300, miss_ttl: 600
      {a_cache_engine, a_cache_options} = case Noizu.AdvancedScaffolding.Internal.Helpers.extract_cache_attribute(:cache, :type, :default) do
                                            {engine, options} -> {engine, options}
                                            v -> {v, []}
                                          end

      a__nzdo__cache_type = case a_cache_engine do
                              :default -> Noizu.DomainObject.CacheHandler.FastGlobal
                              false -> Noizu.DomainObject.CacheHandler.Disabled
                              true -> Noizu.DomainObject.CacheHandler.FastGlobal
                              :fast_global -> Noizu.DomainObject.CacheHandler.FastGlobal
                              :redis -> Noizu.DomainObject.CacheHandler.Redis
                              :redis_json -> Noizu.DomainObject.CacheHandler.RedisJson
                              :con_cache -> Noizu.DomainObject.CacheHandler.ConCache
                              :con -> Noizu.DomainObject.CacheHandler.ConCache
                              :ets -> Noizu.DomainObject.CacheHandler.ConCache
                              :rocksdb ->  Noizu.DomainObject.CacheHandler.RocksDB
                              :rock -> Noizu.DomainObject.CacheHandler.RocksDB
                              :disabled -> Noizu.DomainObject.CacheHandler.Disabled
                              v -> v
                            end


      @__default_telemetry [enabled: false, sample_rate: 0, events: [get: false, get!: false, cache: false, list: false, list!: false, match: false, match!: false]]
      @__default_enabled_telemetry [enabled: false, sample_rate: 100, events: [get: 10, get!: 10, cache: 5, list: 10, list!: 10, match: 10, match!: 10]]
      @__default_light_telemetry [enabled: true, sample_rate: 50, events: [get: false, get!: false, cache: false, list: false, list!: false, match: false, match!: false]]
      @__default_heavy_telemetry [enabled: false, sample_rate: 250, events: [get: 25, get!: 25, cache: 5, list: 25, list!: 25, match: 25, match!: 25]]
      @__default_diagnostic_telemetry [enabled: true, sample_rate: 1000, events: [get: true, get!: true, cache: true, list: true, list!: true, match: true, match!: true]]
      @__default_disabled_telemetry [enabled: false, sample_rate: 0, events: [get: false, get!: false, cache: false, list: false, list!: false, match: false, match!: false]]
      a__nzdo__telemetry = cond do
                             Module.has_attribute?(__MODULE__, :telemetry) -> {:ok, Module.get_attribute(__MODULE__, :telemetry)}
                             unquote(Enum.member?(options,:telemetry)) -> {:ok, unquote(get_in(options, [:telemetry]))}
                             :else -> nil
                           end
                           |> case do
                                nil -> Application.get_env(:noizu_scaffolding, :telemetry)[:default] || @__default_telemetry
                                {:ok, v} when v in [true, :enabled] -> Application.get_env(:noizu_scaffolding, :telemetry)[:enabled] || @__default_enabled_telemetry
                                {:ok, :light} -> Application.get_env(:noizu_scaffolding, :telemetry)[:light] || @__default_light_telemetry
                                {:ok, :heavy} -> Application.get_env(:noizu_scaffolding, :telemetry)[:heavy] || @__default_heavy_telemetry
                                {:ok, :diagnostic} -> Application.get_env(:noizu_scaffolding, :telemetry)[:diagnostic] || @__default_diagnostic_telemetry
                                {:ok, false} -> Application.get_env(:noizu_scaffolding, :telemetry)[:disabled] || @__default_disabled_telemetry
                                {:ok, :disabled} -> Application.get_env(:noizu_scaffolding, :telemetry)[:disabled] || @__default_disabled_telemetry
                                {:ok, v} when is_list(v)->
                                  defaults = Application.get_env(:noizu_scaffolding, :telemetry)[:enabled] || @__default_enabled_telemetry
                                  events = Keyword.merge(defaults[:events] || [], v[:events] || [])
                                  sample_rate = v[:sample_rate] || defaults[:sample_rate] || @__default_enabled_telemetry[:sample_rate]
                                  enabled = if Enum.member?(v, :enabled), do: v[:enabled], else: defaults[:enabled] || false
                                  [enabled: enabled, sample_rate: sample_rate, events: events]
                              end
      @__nzdo__telemetry a__nzdo__telemetry
      
      
      a__nzdo__cache_schema = cond do
                                Keyword.has_key?(a_cache_options, :schema) -> a_cache_options[:schema]
                                :else -> Noizu.AdvancedScaffolding.Internal.Helpers.extract_cache_attribute(:cache_schema, :schema, :default)
                              end
      a__nzdo__cache_prime = cond do
                               Keyword.has_key?(a_cache_options, :prime) -> a_cache_options[:prime]
                               :else ->Noizu.AdvancedScaffolding.Internal.Helpers.extract_cache_attribute(:cache_prime, :prime, true)
                             end
      a__nzdo__cache_ttl = cond do
                             Keyword.has_key?(a_cache_options, :ttl) -> a_cache_options[:ttl]
                             :else -> Noizu.AdvancedScaffolding.Internal.Helpers.extract_cache_attribute(:cache_ttl, :ttl, 3600)
                           end
      a__nzdo__cache_miss_ttl = cond do
                                  Keyword.has_key?(a_cache_options, :miss_ttl) -> a_cache_options[:miss_ttl]
                                  :else -> Noizu.AdvancedScaffolding.Internal.Helpers.extract_cache_attribute(:cache_miss_ttl, :miss_ttl, 30)
                                end
                                
      @__nzdo__auto_generate a__nzdo__auto_generate
      @__nzdo__enum_list a__nzdo__enum_list
      @__nzdo__enum_default_value a__nzdo__enum_default_value
      @__nzdo__enum_ecto_type a__nzdo__enum_ecto_type
      
      @__nzdo__cache_type a__nzdo__cache_type
      @__nzdo__cache_schema a__nzdo__cache_schema
      @__nzdo__cache_prime a__nzdo__cache_prime
      @__nzdo__cache_ttl a__nzdo__cache_ttl
      @__nzdo__cache_miss_ttl a__nzdo__cache_miss_ttl
      
      
      case Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_persistence_attribute(:universal_identifier, :not_set) do
        :not_set -> :skip
        v -> Module.put_attribute(__MODULE__, :universal_identifier, v)
      end

      case Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_persistence_attribute(:generate_reference_type, :reference_type, :not_set) do
        :not_set -> :skip
        v -> Module.put_attribute(__MODULE__, :generate_reference_type, v)
      end

      case Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_persistence_attribute(:universal_lookup, :not_set) do
        :not_set -> :skip
        v -> Module.put_attribute(__MODULE__, :universal_lookup, v)
      end

      a__nzdo_persistence = Noizu.AdvancedScaffolding.Internal.Helpers.extract_transform_attribute(:persistence_layer, :persistence, {Noizu.AdvancedScaffolding.Schema.PersistenceSettings, :__expand_persistence_layers__, [__MODULE__]})
      @__nzdo_persistence a__nzdo_persistence
      a__nzdo_persistence__layers = Enum.map(a__nzdo_persistence.layers, fn (layer) -> {layer.schema, layer} end)
                                    |> Map.new()
      @__nzdo_persistence__layers a__nzdo_persistence__layers
      a__nzdo_persistence__by_table = Enum.map(a__nzdo_persistence.layers, fn (layer) -> {layer.table, layer} end)
                                      |> Map.new()
      @__nzdo_persistence__by_table a__nzdo_persistence__by_table

      a__nzdo_ecto_entity = (a__nzdo_persistence.ecto_entity && true || false)
      @__nzdo_ecto_entity a__nzdo_ecto_entity



      if @__nzdo_ecto_entity do
        @__nzdo__derive Noizu.EctoEntity.Protocol
      end

      if (@__nzdo__base_open?) do
        Module.put_attribute(@__nzdo__base, :__nzdo__cache_type, a__nzdo__cache_type)
        Module.put_attribute(@__nzdo__base, :__nzdo__cache_schema, a__nzdo__cache_schema)
        Module.put_attribute(@__nzdo__base, :__nzdo__cache_prime, a__nzdo__cache_prime)
        Module.put_attribute(@__nzdo__base, :__nzdo__cache_ttl, a__nzdo__cache_ttl)
        Module.put_attribute(@__nzdo__base, :__nzdo__cache_miss_ttl, a__nzdo__cache_miss_ttl)
        
        Module.put_attribute(@__nzdo__base, :__nzdo__auto_generate, a__nzdo__auto_generate)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_list, a__nzdo__enum_list)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_table, a__nzdo_persistence.options.enum_table)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_default_value, a__nzdo__enum_default_value)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_ecto_type, a__nzdo__enum_ecto_type)

        Module.put_attribute(@__nzdo__base, :__nzdo_persistence, a__nzdo_persistence)
        Module.put_attribute(@__nzdo__base, :__nzdo_persistence__layers, a__nzdo_persistence__layers)
        Module.put_attribute(@__nzdo__base, :__nzdo_persistence__by_table, a__nzdo_persistence__by_table)
        Module.put_attribute(@__nzdo__base, :__nzdo_ecto_entity, a__nzdo_ecto_entity)
      end
    end
  end


  #----------------------------------------------------
  # __prepare__nmid__macro__
  #----------------------------------------------------
  defmacro __prepare__nmid__macro__(_) do
    default_nmid_generator = Application.get_env(:noizu_advanced_scaffolding, :default_nmid_generator, Noizu.AdvancedScaffolding.NmidGenerator)
    quote do
      @__nzdo__nmid_generator Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_nmid_attribute(:nmid_generator, :generator, unquote(default_nmid_generator))
      @__nzdo__nmid_sequencer Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_nmid_attribute(:nmid_sequencer, :sequencer, __MODULE__)
      @__nzdo__nmid_index Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_nmid_attribute(:nmid_index, :index, nil)
      @__nzdo__nmid_bare Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_nmid_attribute(:nmid_bare, :bare,  @__nzdo_persistence.options[:enum_table] && true || false)

      if (@__nzdo__base_open?) do
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_generator, @__nzdo__nmid_generator)
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_sequencer, @__nzdo__nmid_sequencer)
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_index, @__nzdo__nmid_index)
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_bare, @__nzdo__nmid_bare)
      end
    end
  end

  #----------------------------------------------------
  # __prepare__json_settings__macro__
  #----------------------------------------------------
  defmacro __prepare__json_settings__macro__(options) do
    quote do
      options = unquote(options)
      json_provider = options[:json_provider]
      json_format = options[:json_format]
      json_white_list = options[:json_white_list]
      json_supported_formats = options[:json_supported_formats]

      @__nzdo__json_provider json_provider || Noizu.AdvancedScaffolding.Internal.Helpers.extract_json_attribute(:json_provider, :provider, Noizu.Poison.Encoder)
      @__nzdo__json_supported_formats json_supported_formats || Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_json_attribute(
        :json_supported_formats, :formats,
        [:standard, :admin, :verbose, :compact, :mobile, :verbose_mobile]
      )
      @__nzdo__json_format json_format || Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_json_attribute(:json_format, :default, List.first(@__nzdo__json_supported_formats))
      @__nzdo__json_format_groups (
                                    Enum.map(
                                      Noizu.AdvancedScaffolding.Internal.Helpers.extract_json_attribute(:json_format_group, :format_groups, []),
                                      fn (group) ->
                                        case group do
                                          {alias, member} when is_atom(member) -> {alias, [members: [member]]}
                                          {alias, members} when is_list(members) -> {alias, [members: members]}
                                          {alias, member, defaults} when is_atom(member) -> {alias, [members: [member], defaults: defaults]}
                                          {alias, members, defaults} when is_list(members) -> {alias, [members: members, defaults: defaults]}
                                          _ -> raise "Invalid @json_formatting_group entry #{inspect group}"
                                        end
                                      end
                                    )
                                    |> Map.new())
      @__nzdo__json_field_groups (
                                   Enum.map(
                                     Noizu.AdvancedScaffolding.Internal.Helpers.extract_json_attribute(:json_field_group, :field_groups, []),
                                     fn (group) ->
                                       case group do
                                         {alias, member} when is_atom(member) -> {alias, [members: [member]]}
                                         {alias, members} when is_list(members) -> {alias, [members: members]}
                                         {alias, member, defaults} when is_atom(member) -> {alias, [members: [member], defaults: defaults]}
                                         {alias, members, defaults} when is_list(members) -> {alias, [members: members, defaults: defaults]}
                                         _ -> raise "Invalid @json_field_group entry #{inspect group}"
                                       end
                                     end
                                   )
                                   |> Map.new())
      @__nzdo__json_white_list (cond do
                                  json_white_list -> json_white_list
                                  :else -> Noizu.AdvancedScaffolding.Internal.Helpers.extract_has_json_attribute(:json_white_list, :white_list, false)
                                end)

      __nzdo__json_config = %{
        provider: @__nzdo__json_provider,
        default_format: @__nzdo__json_format,
        white_list: @__nzdo__json_white_list,
        selection_groups: @__nzdo__json_format_groups,
        field_groups: @__nzdo__json_field_groups,
        supported: @__nzdo__json_supported_formats
      }
      Module.put_attribute(__MODULE__, :__nzdo__json_config, __nzdo__json_config)

      if (@__nzdo__base_open? && !options[:for_repo]) do
        Module.put_attribute(@__nzdo__base, :__nzdo__json_provider, @__nzdo__json_provider)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_format, @__nzdo__json_format)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_supported_formats, @__nzdo__json_supported_formats)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_format_groups, @__nzdo__json_format_groups)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_field_groups, @__nzdo__json_field_groups)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_white_list, @__nzdo__json_white_list)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_config, @__nzdo__json_config)
      end
    end
  end


  #--------------------------------------------
  # extract_transform_attribute
  #--------------------------------------------
  defmacro extract_transform_attribute(attribute, setting, mfa, default \\ nil) do
    quote do
      cond do
        v = Module.get_attribute(__MODULE__, unquote(attribute)) ->
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(unquote(setting)) -> @__nzdo__base.__noizu_info__(unquote(setting))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) ->
          v = Module.get_attribute(@__nzdo__base, unquote(attribute))
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(unquote(setting)) -> @__nzdo__poly_base.__noizu_info__(unquote(setting))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) ->
          v = Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
        :else ->
          v = unquote(default)
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
      end
    end
  end

  #--------------------------------------------
  # extract_has_attribute
  #--------------------------------------------
  defmacro extract_has_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(unquote(property)) != nil -> @__nzdo__base.__noizu_info__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(unquote(property)) != nil -> @__nzdo__poly_base.__noizu_info__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end


  #--------------------------------------------
  # extract_cache_attribute
  #--------------------------------------------
  defmacro extract_cache_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__cache_configuration__(unquote(property)) != nil -> @__nzdo__base.__cache_configuration__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__cache_configuration__(unquote(property)) != nil -> @__nzdo__poly_base.__cache_configuration__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end

  #--------------------------------------------
  # extract_has_json_attribute
  #--------------------------------------------
  defmacro extract_has_json_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__json__(unquote(property)) != nil -> @__nzdo__base.__json__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__json__(unquote(property)) != nil -> @__nzdo__poly_base.__json__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end


  #--------------------------------------------
  # extract_has_enum_attribute
  #--------------------------------------------
  defmacro extract_has_enum_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__enum__(unquote(property)) != nil -> @__nzdo__base.__enum__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__enum__(unquote(property)) != nil -> @__nzdo__poly_base.__enum__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end



  #--------------------------------------------
  # extract_has_nmid_attribute
  #--------------------------------------------
  defmacro extract_has_nmid_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__nmid__(unquote(property)) != nil -> @__nzdo__base.__nmid__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__nmid__(unquote(property)) != nil -> @__nzdo__poly_base.__nmid__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end




  #--------------------------------------------
  # extract_has_persistence_attribute
  #--------------------------------------------
  defmacro extract_has_persistence_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__persistence__(unquote(property)) != nil -> @__nzdo__base.__persistence__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__persistence__(unquote(property)) != nil -> @__nzdo__poly_base.__persistence__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end

  #--------------------------------------------
  # extract_attribute
  #--------------------------------------------
  defmacro extract_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        v = Module.get_attribute(__MODULE__, unquote(attribute)) -> v
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(unquote(property)) -> @__nzdo__base.__noizu_info__(unquote(property))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(unquote(property)) -> @__nzdo__poly_base.__noizu_info__(unquote(property))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end


  #--------------------------------------------
  # extract_json_attribute
  #--------------------------------------------
  defmacro extract_json_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        v = Module.get_attribute(__MODULE__, unquote(attribute)) -> v
        !@__nzdo__base_open? && @__nzdo__base.__json__(unquote(property)) -> @__nzdo__base.__json__(unquote(property))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__json__(unquote(property)) -> @__nzdo__poly_base.__json__(unquote(property))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end


  #--------------------------------------------
  # file_rel_dir
  #--------------------------------------------
  @doc """
  Obtain Relative File Path
  """
  def file_rel_dir(module_path) do
    offset = file_rel_dir(__ENV__.file, module_path, 0)
    String.slice(module_path, offset..- 1)
  end
  defp file_rel_dir(<<m>> <> a, <<m>> <> b, acc) do
    file_rel_dir(a, b, 1 + acc)
  end
  defp file_rel_dir(_a, _b, acc), do: acc


  #--------------------------------------------
  # module_rel
  #--------------------------------------------
  @doc """
    Strip prefixes from Module. (e.g. remove Noizu.AdvancedScaffolding).
  """
  def module_rel(base, module_path) do
    [_ | a] = base
    [_ | b] = module_path
    offset = module_rel(a, b, 0)
    Enum.slice(module_path, (offset + 1)..- 1)
  end
  defp module_rel([h | a], [h | b], acc), do: module_rel(a, b, 1 + acc)
  defp module_rel(_a, _b, acc), do: acc
end
