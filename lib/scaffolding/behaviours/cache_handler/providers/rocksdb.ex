if Code.ensure_loaded?(:rocksdb) do

  defmodule Noizu.RocksDB do
    @moduledoc """
    The `Noizu.RocksDB` module provides functions for interacting with a RocksDB database.

    # Functions
    - `resource_ok/1`: Checks if the RocksDB resource handle is valid.
    - `get/3`: Retrieves a value from the RocksDB database.
    - `delete/4`: Deletes a key-value pair from the RocksDB database.
    - `put/4`: Inserts or updates a key-value pair in the RocksDB database.
    """


    #------------------------------------------
    # resource_ok
    #------------------------------------------
    @doc """
    Checks if the RocksDB resource handle is valid.

    ## Params
    - handle: The resource handle.

    ## Returns
    - {:ok, resource}: The RocksDB resource if it is valid.
    - {:error, :no_handle}: The resource handle is not valid.
    - {:error, reason}: An error reason for the failure.
    """
    @spec resource_ok(any()) :: {:ok, any()} | {:error, any()}
    def resource_ok(handle) do
      case :ets.lookup(:rocksdb_resource_lookup, {Noizu.RocksDB, handle}) do
      [{{Noizu.RocksDB, ^handle}, r}|_] -> {:ok, r}
      [] -> {:error, :ets.info(:rocksdb_resource_lookup)}
      v -> {:error, {:config, v}}
      end
    end


    #------------------------------------------
    # get
    #------------------------------------------
    @doc """
    Retrieves a value from the RocksDB database.

    ## Params
    - handle: The resource handle.
    - key: The key to retrieve the value for.
    - options: A keyword list of options.

    ## Returns
    - {:ok, value}: The retrieved value.
    - {:error, :no_handle}: The resource handle is not valid.
    - error: An error that may occur during value retrieval.
    """
    @spec get(any(), any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
    def get(handle, key, options \\ [])
    def get(handle, key, options) do
      with {:ok, resource} <- resource_ok(handle),
           {:ok, v} <- resource && :rocksdb.get(resource, key, options) || {:error, :no_handle} do
        {:ok, :erlang.binary_to_term(v)}
      else
        error -> error
      end
    end


    #------------------------------------------
    # delete
    #------------------------------------------
    @doc """
    Deletes a key-value pair from the RocksDB database.

    ## Params
    - handle: The resource handle.
    - key: The key of the pair to delete.
    - value: value of the key (unused)
    - options: A keyword list of options.

    ## Returns
    - {:ok, value}: The deleted value.
    - {:error, :no_handle}: The resource handle is not valid.
    - error: An error that may occur during deletion.
    """
    @spec delete(any(), any(), any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
    def delete(handle, key, value, options \\ [])
    def delete(handle, key, _value, options ) do
      with {:ok, resource} <- resource_ok(handle),
           {:ok, v} <- resource && :rocksdb.delete(resource, key, options) || {:error, :no_handle} do
        {:ok, v}
      else
        error -> error
      end
    end


    #------------------------------------------
    # put
    #------------------------------------------
    @doc """
    Inserts or updates a key-value pair in the RocksDB database.

    ## Params
    - handle: The resource handle.
    - key: The key of the pair to insert/update.
    - value: The value to insert/update.
    - options: A keyword list of options.

    ## Returns
    - {:ok, value}: The inserted/updated value.
    - {:error, :no_handle}: The resource handle is not valid.
    - error: An error that may occur during insertion/updating.
    """
    @spec put(any(), any(), any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
    def put(handle, key, value, options \\ [])
    def put(handle, key, value, options) do
      with {:ok, resource} <- resource_ok(handle),
           {:ok, v} <- resource && :rocksdb.put(resource, key, :erlang.term_to_binary(value), options) || {:error, :no_handle} do
        {:ok, v}
      else
        error -> error
      end
    end
  end

  defmodule Noizu.RocksDB.Monitor do
    @moduledoc """
    The `Noizu.RocksDB.Monitor` module is a GenServer process for monitoring RocksDB resources.

    # Functions
    - `start_link/2`: Starts the RocksDB monitor process.
    """

    use GenServer
    require Logger
    @default_data_dir "/etc/rocksdb/data-dir"

    @default_options [
      create_if_missing: true,
      total_threads: 500,
      max_open_files: 100_000,
    ]

    #------------------------------------------
    # start_link
    #------------------------------------------
    @doc """
    Starts the RocksDB monitor process.

    ## Params
    - name: The name of the monitor process.
    - settings: The settings for the monitor process.

    ## Returns
    - :ok: The monitor process was started successfully.
    - {:error, reason}: An error reason for the failure.
    """
    @spec start_link(atom(), map()) :: :ok | {:error, any()}
    def start_link(name, settings) do
      GenServer.start_link(__MODULE__, [name: name, settings: settings], [] )
    end


    #------------------------------------------
    # init
    #------------------------------------------
    @doc """
    Initializes the RocksDB monitor process.

    ## Params
    - state: The initial state of the monitor process.

    ## Returns
    - {:ok, state}: The monitor process was initialized successfully.
    - {:error, any()}: An error that may occur during initialization.
    """
    @spec init(any()) :: {:ok, any()} | {:error, any()}
    def init(state)
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


    #------------------------------------------
    # terminate
    #------------------------------------------
    @doc """
    Terminates the RocksDB monitor process.

    ## Params
    - reason: The termination reason.
    - state: The current state of the monitor process.

    ## Returns
    - {:ok, state}: The monitor process was terminated successfully.
    """
    @spec terminate(any(), any()) :: {:ok, any()}
    def terminate(reason, state)
    def terminate(_reason, state) do
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


    #------------------------------------------
    # handle_info
    #------------------------------------------
    @doc """
    Handles incoming messages for the RocksDB monitor process.

    ## Params
    - call: The incoming message.
    - state: The current state of the monitor process.

    ## Returns
    - {:ok, state}: The monitor process handled the message successfully.
    """
    @spec handle_info(any(), any()) :: {:ok, any()}
    def handle_info(call, state)
    def handle_info(call, state) do
      Logger.info("[Noizu.RocksDB] - Unhandled #{state[:name]} - #{inspect call}")
      {:ok, state}
    end
  end

  defmodule Noizu.RocksDB.Supervisor do
    @moduledoc """
    The `Noizu.RocksDB.Supervisor` module is a Supervisor process for managing RocksDB monitors.

    # Functions
    - `start_link/1`: Starts the RocksDB Supervisor process.
    """

    use Supervisor


    #------------------------------------------
    # start_link
    #------------------------------------------
    @doc """
    Starts the RocksDB Supervisor process.

    ## Params
    - children: The child processes.
    - options: A keyword list of options.

    ## Returns
    - :ok: The Supervisor process was started successfully.
    - {:error, reason}: An error reason for the failure.
    """
    @spec start_link({[map()], Keyword.t()}) :: :ok | {:error, any()}
    def start_link({children, options})
    def start_link({children, options}) do
      Supervisor.start_link(__MODULE__, {children, options}, name: __MODULE__)
    end

    #------------------------------------------
    # init
    #------------------------------------------
    @doc """
    Initializes the RocksDB Supervisor process.

    ## Params
    - state: The initial state of the Supervisor process.

    ## Returns
    - {:ok, state}: The Supervisor process was initialized successfully.
    - {:error, any()}: An error that may occur during initialization.
    """
    @spec init(any()) :: {:ok, any()} | {:error, any()}
    def init({children, options})
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

    #------------------------------------------
    # cache_key
    #------------------------------------------
    @doc """
    Generates a cache key based on the given DomainObject, ref, context, and options.

    ## Params
    - m: The DomainObject module.
    - ref: The reference to the DomainObject.
    - _context: The request context.
    - _options: A keyword list of options.

    ## Returns
    - The cache key.
    """
    @spec cache_key(module(), any(), any(), Keyword.t()) :: any()
    def cache_key(m, ref, _context, _options)
    def cache_key(m, ref, _context, _options) do
      m.__entity__.sref_ok(ref)
    end

    #------------------------------------------
    # delete_cache
    #------------------------------------------
    @doc """
    Deletes a cache entry for the given DomainObject, ref, context, and options.

    ## Params
    - m: The DomainObject module.
    - ref: The reference to the DomainObject.
    - context: The request context.
    - options: A keyword list of options.

    ## Returns
    - :ok: The cache entry was deleted successfully.
    - {:error, :config}: An error occurred due to configuration issues.
    - error: Any other error that may occur during cache deletion.
    """
    @spec delete_cache(module(), any(), any(), Keyword.t()) :: :ok | {:error, any()} | any()
    def delete_cache(m, ref, context, options)
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
    @doc """
    Pre-caches a DomainObject with the given ref, context, and options.

    ## Params
    - m: The DomainObject module.
    - ref: The reference to the DomainObject.
    - context: The request context.
    - options: A keyword list of options.

    ## Returns
    - ref: The reference to the pre-cached DomainObject.
    - error: An error that may occur during pre-caching the DomainObject.
    """
    @spec pre_cache(module(), any(), any(), Keyword.t()) :: any() | any()
    def pre_cache(m, ref, context, options)
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

#    defp __cache_ttl__(m, options) do
#      cond do
#        v = options[:cache][:ttl] -> v
#        v = m.__noizu_info__(:cache)[:ttl] -> v
#        :else -> :inherit
#      end
#    end

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
    @doc """
    Retrieves a cached DomainObject with the given ref, context, and options.

    ## Params
    - m: The DomainObject module.
    - ref: The reference to the DomainObject.
    - context: The request context.
    - options: A keyword list of options.

    ## Returns
    - The cached DomainObject.
    """
    @spec get_cache(module(), any(), any(), Keyword.t()) :: any()
    def get_cache(m, ref, context, options)
    def get_cache(_m, nil, _context, _options), do: nil
    def get_cache(m, ref, context, options) do
      with {:ok, cache_key} <- m.cache_key(ref, context, options) do
        cond do
          schema = __cache_schema__(m, options) ->
            emit = m.emit_telemetry?(:cache, ref, context, options)
            emit && :telemetry.execute(m.telemetry_event(:cache, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})

            case  Noizu.RocksDB.get(schema, cache_key, options[:rocksdb]) do
              {:ok, {:cache_miss, v}} ->
                cond do
                  v < :os.system_time(:second) ->
                    emit && :telemetry.execute(m.telemetry_event(:cache_miss, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
                    __cache_miss__(m, schema, cache_key, ref, context, options)
                  :else -> {:ok, :cache_miss}
                end
              {:ok, :cache_miss} -> {:ok, :cache_miss}
              {:ok, nil} ->
                emit && :telemetry.execute(m.telemetry_event(:cache_miss, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
                __cache_miss__(m, schema, cache_key, ref, context, options)
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

    defdelegate cache_key(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled
    defdelegate delete_cache(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled
    defdelegate pre_cache(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled
    defdelegate get_cache(m, ref, context, options), to: Noizu.DomainObject.CacheHandler.Disabled

  end


end
