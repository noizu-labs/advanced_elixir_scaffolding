defmodule Noizu.DomainObject.CacheHandler.FastGlobal do
  @behaviour Noizu.DomainObject.CacheHandler

  #------------------------------------------
  # cache_key
  #------------------------------------------
  @doc """
  Generates a cache key based on the given DomainObject, ref, context, and options.

  ## Params
  - m: The DomainObject module.
  - ref: The reference to the DomainObject.
  - context: The request context.
  - options: A keyword list of options.

  ## Returns
  - sref: The serialized reference of the DomainObject, used as the cache key.
  - nil: The cache key could not be generated.
  """
  @spec cache_key(module(), any(), any(), Keyword.t()) :: atom() | nil
  def cache_key(m, ref, context, options)
  def cache_key(m, ref, _context, _options) do
    sref = m.__entity__.sref(ref)
    sref && :"e_c:#{sref}"
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
  - error: An error that may occur during cache deletion.
  """
  @spec delete_cache(module(), any(), any(), Keyword.t()) :: :ok | any()
  def delete_cache(m, ref, context, options)
  def delete_cache(m, ref, context, options) do
    # @todo use noizu fg cluster
    cond do
      key = m.cache_key(ref, context, options) ->
        spawn fn ->
          (options[:nodes] || Node.list())
          |> Task.async_stream(fn (n) -> :rpc.cast(n, FastGlobal, :delete, [key]) end)
          |> Enum.map(&(&1))
        end
        FastGlobal.delete(key)
      :else -> throw "Invalid Ref #{m}.delete_cache(#{inspect ref})"
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
  """
  @spec pre_cache(module(), any(), any(), Keyword.t()) :: any()
  def pre_cache(m, ref, context, options)
  def pre_cache(_m, nil, _context, _options), do: nil
  def pre_cache(m, ref, context, options) do
    cond do
      cache_key = m.cache_key(ref, context, options) ->
        Noizu.FastGlobal.Cluster.put(
          cache_key,
          m.__entity__().__to_cache__!(ref, context, options),
          options
        )
        ref
      :else -> throw "#{m}.cache invalid ref #{inspect ref}"
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
    cond do
      cache_key = m.cache_key(ref, context, options) ->
        emit = m.emit_telemetry?(:cache, ref, context, options)
        emit && :telemetry.execute(m.telemetry_event(:cache, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
  
  
        v = Noizu.FastGlobal.Cluster.get(
          cache_key,
          fn () ->
            emit && :telemetry.execute(m.telemetry_event(:cache_miss, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
            cond do
              entity = m.get!(ref, context, options) ->
                m.__entity__().__to_cache__!(entity, context, options)
              :else -> {:cache_miss, :os.system_time(:second) + 30 + :rand.uniform(300)}
            end
          end
        )

        case v do
          {:cache_miss, cut_off} ->
            cond do
              options[:cache_second_attempt] -> nil
              (cut_off < :os.system_time(:second)) ->
                FastGlobal.delete(cache_key)
                options = put_in(options || %{}, [:cache_second_attempt], true)
                m.cache(ref, context, options)
              :else -> nil
            end
          _else ->
            case m.__entity__().__from_cache__!(v, context, options) do
              {:cache, directive} when directive in [:refresh, :expired] ->
                FastGlobal.delete(cache_key)
                nil
              {:cache, _} -> nil
              {:error, _} -> nil
              v -> v
            end
        end
      :else -> throw "#{m}.cache invalid ref #{inspect ref}"
    end
  end
end
