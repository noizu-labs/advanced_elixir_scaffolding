defmodule Noizu.DomainObject.CacheHandler.ConCache do
  @behaviour Noizu.DomainObject.CacheHandler
  require Logger

  #-----------------------------
  # Compile Time Constants
  #-----------------------------
  @default_schema Application.get_env(:noizu_advanced_scaffolding, :cache)[:default_con_cache] || ConCache.Default
  
  #====================================================
  # Functions
  #====================================================
  
  
  def cache_key(m, ref, _context, _options) do
    m.__entity__.ref_ok(ref)
  end
  
  
  def __write__(cache_key, value, options \\ nil) do
    ttl = options[:ttl] || :inherit
    schema = cond do
                  options[:schema] in [:default, nil] -> @default_schema
                  :else -> options[:schema]
             end
    cond do
      ttl == :inherit -> ConCache.dirty_put(schema, cache_key, value)
      :else -> ConCache.dirty_put(schema, cache_key, %ConCache.Item{value: value, ttl: ttl})
    end
  end
  
  def __clear__(cache_key, options \\ nil) do
    schema = cond do
               options[:schema] in [:default, nil] -> @default_schema
               :else -> options[:schema]
             end
    ConCache.dirty_delete(schema, cache_key)
  end
  
  def __fetch__(cache_key, default \\ :no_cache, options \\ nil) do
    schema = cond do
               options[:schema] in [:default, nil] -> @default_schema
               :else -> options[:schema]
             end
    default = cond do
                default == :no_cache -> fn -> {:error, :cache_miss} end
                is_function(default, 0) -> default
                :else -> fn() -> {:ok, default} end
              end
    ConCache.dirty_fetch_or_store(schema, cache_key, default)
  end
  
  
  #------------------------------------------
  # delete_cache
  #------------------------------------------
  def delete_cache(m, ref, context, options) do
    cond do
      schema = __cache_schema__(m, options) ->
        with {:ok, key} <- m.cache_key(ref, context, options) do
          ConCache.dirty_delete(schema, key)
        else
          error ->
            Logger.warn(fn -> "[C:CONCACHE] Invalid Ref #{inspect error}" end)
            error
        end
      :else ->
        {:error, :config}
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
          ttl = __cache_ttl__(m, options)
          cond do
            ttl == :inherit -> ConCache.dirty_put(schema, cache_key, stripped_entity)
            :else -> ConCache.dirty_put(schema, cache_key, %ConCache.Item{value: stripped_entity, ttl: ttl})
          end
          ref
        :else ->
          Logger.error("[C:CON_CACHE] Schema NOT SPECIFIED (#{inspect m})")
          throw "[C:CON_CACHE] Schema NOT SPECIFIED (#{inspect m})"
      end
    else
      error -> throw "[C:CON_CACHE] #{m}.cache invalid ref #{inspect error}"
    end
  end
  
  
  
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
      :else -> 30
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
  def __cache_miss__(m, _, _, ref, context, options) do
    with {:ok, ref} <- m.__entity__().ref_ok(ref) do
      cond do
        __auto_prime_cache__(m, options) == false ->
          {:error, :do_not_prime}
        e = m.get!(ref, context, options) ->
          {:ok, m.__entity__().__to_cache__!(e, context, options)}
        :else ->
          ttl = __miss_ttl__(m, options)
          cond do
            ttl == :inherit -> {:ok, :cache_miss}
            :else -> {:ok, %ConCache.Item{value: :cache_miss, ttl: ttl}}
          end
      end
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
          ConCache.dirty_fetch_or_store(schema, cache_key, fn() ->
            __cache_miss__(m, schema, cache_key, ref, context, options)
          end) |> case do
                    {:ok, :cache_miss} -> nil
                    {:ok, v} ->
                      case m.__entity__().__from_cache__!(v, context, options) do
                        {:cache, directive} when directive in [:refresh, :expired] ->
                          ConCache.dirty_delete(schema, cache_key)
                        {:cache, _} -> nil
                        {:error, _} -> nil
                        v -> v
                      end
                      
                    _ -> nil
                  end
        :else ->
          Logger.error("[C:CON_CACHE] Schema NOT SPECIFIED (#{m})")
          throw "[C:CON_CACHE] Schema NOT SPECIFIED (#{m})"
      end
    else
      error ->
        throw "[C:CON_CACHE] #{m}.cache invalid ref #{inspect error}"
    end
  end
end