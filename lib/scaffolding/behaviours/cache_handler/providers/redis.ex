defmodule Noizu.DomainObject.CacheHandler.Redis do
  @behaviour Noizu.DomainObject.CacheHandler
  require Logger
  
  def cache_key(m, ref, _context, _options) do
    case m.__entity__.sref_ok(ref) do
      {:ok, sref} -> {:ok, sref <> ".bin"}
      e -> e
    end
  end
  
  #------------------------------------------
  # delete_cache
  #------------------------------------------
  def delete_cache(m, ref, context, options) do
    cond do
      redis = __cache_schema__(m, options) ->
        with {:ok, key} <- m.cache_key(ref, context, options) do
          redis.delete(key)
        else
          error ->
            Logger.warn(fn -> "[C:REDIS] Invalid Ref #{inspect error}" end)
            error
        end
      :else ->
        Logger.error("[C:REDIS] REDIS NOT SPECIFIED (#{inspect m})")
        {:error, :config}
    end
  end
  
  #------------------------------------------
  # pre_cache
  #------------------------------------------
  def pre_cache(m, ref, context, options) do
    with {:ok, cache_key} <- m.cache_key(ref, context, options) do
      cond do
        redis = __cache_schema__(m, options) ->
          stripped_entity = m.__entity__().__to_cache__!(ref, context, options)
          # Extract TTL here.
          ttl = __cache_ttl__(m, options)
          cond do
            ttl == :infinity -> redis.set_binary([cache_key, stripped_entity])
            :else -> redis.set_binary([cache_key, stripped_entity, "EX", ttl])
          end
          ref
        :else ->
          Logger.error("[C:REDIS] REDIS NOT SPECIFIED (#{inspect m})")
          throw "[C:REDIS] REDIS NOT SPECIFIED (#{inspect m})"
      end
    else
      error -> throw "[C:REDIS] #{m}.cache invalid ref #{inspect error}"
    end
  end
  
  defp __cache_schema__(m, options) do
    cond do
      v = options[:cache][:schema] -> v
      m.__noizu_info__(:cache)[:schema] in [:default, nil] -> Noizu.AdvancedScaffolding.Schema.PersistenceSettings.__default_redis_repo__(m)
      :else -> m.__noizu_info__(:cache)[:schema]
    end
  end
  
  defp __cache_ttl__(m, options) do
    cond do
      v = options[:cache][:ttl] -> v
      v = m.__noizu_info__(:cache)[:ttl] -> v
      :else -> 300
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
  def __cache_miss__(m, redis, cache_key, ref, context, options) do
    with {:ok, ref} <- m.__entity__.ref_ok(ref) do
      cond do
        __auto_prime_cache__(m, options) == false ->
          nil
        e = m.get!(ref, context, options) ->
          is_struct(e) && m.pre_cache(e, context, options)
          e
        :else ->
          ttl = __miss_ttl__(m, options)
          cond do
            ttl == :infinity -> redis.set_binary([cache_key, :cache_miss])
            :else -> redis.set_binary([cache_key, :cache_miss, "EX", ttl])
          end
          nil
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
        redis = __cache_schema__(m, options) ->
          emit = m.emit_telemetry?(:cache, ref, context, options)
          emit && :telemetry.execute(m.telemetry_event(:cache, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
          case redis.get_binary(cache_key) do
            {:ok, :cache_miss} ->
              nil
            {:ok, nil} ->
              emit && :telemetry.execute(m.telemetry_event(:cache_miss, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
              __cache_miss__(m, redis, cache_key, ref, context, options)
            {:ok, json} ->
              case m.__entity__().__from_cache__!(json, context, options) do
                {:cache, directive} when directive in [:refresh, :expired] ->
                  emit && :telemetry.execute(m.telemetry_event(:cache_miss, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
                  __cache_miss__(m, redis, cache_key, ref, context, options)
                {:cache, _} -> nil
                {:error, _} -> nil
                v -> v
              end
            _ ->
              emit && :telemetry.execute(m.telemetry_event(:cache_miss, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
              __cache_miss__(m, redis, cache_key, ref, context, options)
          end
        :else ->
          Logger.error("[C:REDIS] REDIS NOT SPECIFIED (#{m})")
          throw "[C:REDIS] REDIS NOT SPECIFIED (#{m})"
      end
    else
      error ->
        throw "[C:REDIS] #{m}.cache invalid ref #{inspect error}"
    end
  end
end