if Code.ensure_loaded?(:rocksdb) do
  
  defmodule Noizu.RocksDB do
    def resource_ok(handle) do
      case :ets.lookup(:rocksdb_resource_lookup, {Noizu.RocksDB, handle}) do
      [{{Noizu.RocksDB, ^handle}, r}|_] -> {:ok, r}
      [] -> {:error, :ets.info(:rocksdb_resource_lookup)}
      v -> {:error, {:config, v}}
      end
    end
                            
    def get(handle, key, options \\ []) do
      with {:ok, resource} <- resource_ok(handle),
           {:ok, v} <- resource && :rocksdb.get(resource, key, options) || {:error, :no_handle} do
        {:ok, :erlang.binary_to_term(v)}
      else
        error -> error
      end
    end
    
    def delete(handle, key, value, options \\ []) do
      with {:ok, resource} <- resource_ok(handle),
           {:ok, v} <- resource && :rocksdb.delete(resource, key, options) || {:error, :no_handle} do
        {:ok, v}
      else
        error -> error
      end
    end
    
    def put(handle, key, value, options \\ []) do
      with {:ok, resource} <- resource_ok(handle),
           {:ok, v} <- resource && :rocksdb.put(resource, key, :erlang.term_to_binary(value), options) || {:error, :no_handle} do
        {:ok, v}
      else
        error -> error
      end
    end
  end
  
  defmodule Noizu.RocksDB.Monitor do
    use GenServer
    require Logger
    @default_data_dir "/etc/rocksdb/data-dir"
    
    @default_options [
      create_if_missing: true,
      total_threads: 500,
      max_open_files: 100_000,
    ]
    
    def start_link(name, settings) do
      GenServer.start_link(__MODULE__, [name: name, settings: settings], [] )
    end
    
    def init(state) do
      base_options = Application.get_env(:advanced_elixir_scaffolding, :rocksdb)[:options] || @default_options
      effective_options = Keyword.merge(state[:settings][:options] || [], base_options)
      data_dir = cond do
                   state[:settings][:data_dir] in [nil, :default] -> Application.get_env(:advanced_elixir_scaffolding, :rocksdb)[:data_dir] || @default_data_dir
                   :else -> state[:settings][:data_dir]
                 end

      path = "#{data_dir}/#{node()}/#{state[:name]}"
      File.mkdir_p(path)
      source = String.to_charlist(path)
      
      # todo open type.
      case  :rocksdb.open(source, effective_options) do
        {:ok, r} ->
         :ets.insert(:rocksdb_resource_lookup, {{Noizu.RocksDB, state[:name]}, r})
          state = state
                  |> put_in([:effective_options], effective_options)
                  |> put_in([:resource], r)
          {:ok, state}
        e ->
          # @todo deal with failure.
          state = state
                  |> put_in([:effective_options], effective_options)
                  |> put_in([:resource], e)
          {:ok, state}
      end
    end
    
    
    def terminate(reason, state) do
      case state[:resource] do
        {:error, _} -> {:ok, state}
        r  ->
          try do
            :rocksdb.close(r)
            :ets.insert(:rocksdb_resource_lookup, {{Noizu.RocksDB, state[:name]}, r})
          rescue _ -> :swallow
          catch :exit, _ -> :swallow
            _ -> :swallow
          end
      end
    end
    
    
    def handle_info(call, state) do
      Logger.info("[Noizu.RocksDB] - Unhandled #{state[:name]} - #{inspect call}")
      {:ok, state}
    end
  end
  
  defmodule Noizu.RocksDB.Supervisor do
    use Supervisor
    def start_link({children, options}) do
      Supervisor.start_link(__MODULE__, {children, options}, name: __MODULE__)
    end
    
    def init({children, options}) do
      :ets.new(:rocksdb_resource_lookup, [:public, :named_table, :set, read_concurrency: true])
      
      c = Enum.map(children,
      fn(c) ->
        {id, op} = case c do
                     c when is_atom(c) -> {c, []}
                     {a,b} -> {a,b}
                   end
        %{
          id: id,
          start: {Noizu.RocksDB.Monitor, :start_link, [id, op]}
        }
      end )
      config = Keyword.merge([strategy: :one_for_one, max_restarts: 5000, max_seconds: 1], options || [])
      Supervisor.init(c, config)
    end
  end


  defmodule Noizu.DomainObject.CacheHandler.RocksDB do
    @behaviour Noizu.DomainObject.CacheHandler
    @log_name "C:ROCKSDB"
    require Logger
  
    def cache_key(m, ref, _context, _options) do
      m.__entity__.sref_ok(ref)
    end
  
    #------------------------------------------
    # delete_cache
    #------------------------------------------
    def delete_cache(m, ref, context, options) do
      cond do
        schema = __cache_schema__(m, options) ->
          with {:ok, key} <- m.cache_key(ref, context, options) do
            Noizu.RocksDB.delete(schema, key, options[:rocksdb])
          else
            error ->
              Logger.warn(fn -> "[#{@log_name}] Invalid Ref #{inspect error}" end)
              error
          end
        :else ->
          {:error, :config2}
      end
    end
  
    #------------------------------------------
    # pre_cache
    #------------------------------------------
    def pre_cache(m, ref, context, options) do
      with {:ok, cache_key} <- m.cache_key(ref, context, options) do
        cond do
          schema = __cache_schema__(m, options) ->
            stripped_entity = m.__entity__().__to_cache__!(ref, context, options)
            Noizu.RocksDB.put(schema, cache_key, stripped_entity, options[:rocksdb])
            ref
          :else ->
            Logger.error("[#{@log_name}] Schema NOT SPECIFIED (#{inspect m})")
            throw "[#{@log_name}] Schema NOT SPECIFIED (#{inspect m})"
        end
      else
        error -> throw "[#{@log_name}] #{m}.cache invalid ref #{inspect error}"
      end
    end
  
  
    @default_schema Application.get_env(:noizu_advanced_scaffolding, :cache)[:rocksdb][:default_schema] || EntityCache
    defp __cache_schema__(m, options) do
      cond do
        v = options[:cache][:schema] -> v == :default && @default_schema || v
        m.__noizu_info__(:cache)[:schema] in [:default, nil] -> @default_schema
        :else -> m.__noizu_info__(:cache)[:schema]
      end
    end
  
    defp __cache_ttl__(m, options) do
      cond do
        v = options[:cache][:ttl] -> v
        v = m.__noizu_info__(:cache)[:ttl] -> v
        :else -> :inherit
      end
    end
  
    defp __miss_ttl__(m, options) do
      cond do
        v = options[:cache][:miss_ttl] -> v
        v = m.__noizu_info__(:cache)[:miss_ttl] -> v
        :else -> 600
      end
    end
  
    defp __auto_prime_cache__(m, options) do
      cond do
        options[:cache][:prime] == false -> false
        v = options[:cache][:prime] -> v
        m.__noizu_info__(:cache)[:prime] == false -> false
        v = m.__noizu_info__(:cache)[:prime] -> v
        :else -> false
      end
    end
  
    @doc """
    @TODO - Telemetry
    """
    def __cache_miss__(m, schema, cache_key, ref, context, options) do
      with {:ok, ref} <- m.__entity__.ref_ok(ref) do
        cond do
          __auto_prime_cache__(m, options) == false -> {:ok, :cache_miss}
          e = m.get!(ref, context, options) ->
            pre_cache(m,ref,context,options)
            {:ok, e}
          :else ->
            ttl = case __miss_ttl__(m, options) do
                    v when is_integer(v) -> v
                    :else -> 600
                  end
            ttl =:os.system_time(:second) + ttl
            # Cache cache miss status.
            Noizu.RocksDB.put(schema, cache_key, {:cache_miss, ttl}, options[:rocksdb])
            {:ok, :cache_miss}
        end
      else
        error -> error
      end
    end
  
    #------------------------------------------
    # get_cache
    #------------------------------------------
    def get_cache(_m, nil, _context, _options), do: nil
    def get_cache(m, ref, context, options) do
      with {:ok, cache_key} <- m.cache_key(ref, context, options) do
        cond do
          schema = __cache_schema__(m, options) ->
          
            case  Noizu.RocksDB.get(schema, cache_key, options[:rocksdb]) do
              {:ok, {:cache_miss, v}} ->
                cond do
                  v < :os.system_time(:second) -> __cache_miss__(m, schema, cache_key, ref, context, options)
                  :else -> {:ok, :cache_miss}
                end
              {:ok, :cache_miss} -> {:ok, :cache_miss}
              {:ok, nil} -> __cache_miss__(m, schema, cache_key, ref, context, options)
              {:ok, v} -> {:ok, v}
              v -> v
            end |> case do
                     {:ok, :cache_miss} -> nil
                     {:ok, v} -> v
                     _ -> nil
                   end
          :else ->
            Logger.error("[#{@log_name}] Schema NOT SPECIFIED (#{m})")
            throw "[#{@log_name}] Schema NOT SPECIFIED (#{m})"
        end
      else
        error ->
          throw "[#{@log_name}] #{m}.cache invalid ref #{inspect error}"
      end
    end

  end
  
else
  
  
  defmodule Noizu.DomainObject.CacheHandler.RocksDB do
    @behaviour Noizu.DomainObject.CacheHandler
    
    def cache_key(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled
    def delete_cache(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled
    def pre_cache(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled
    def get_cache(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled
    
  end
  
  
end
