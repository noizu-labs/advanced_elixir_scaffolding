defmodule Noizu.DomainObject.CacheHandler.FastGlobal do
  @behaviour Noizu.DomainObject.CacheHandler


  def __write__(cache_key, value, options \\ nil) do
    cond do
      options[:raw] == false -> Noizu.FastGlobal.V3.Cluster.put(cache_key, value, options)
      :else -> FastGlobal.put(cache_key, value)
    end
  end

  def __clear__(cache_key, options \\ nil) do
    cond do
      options[:raw] == false -> Noizu.FastGlobal.V3.Cluster.delete(cache_key, options)
      :else -> FastGlobal.delete(cache_key)
    end
  end

  def __fetch__(cache_key, default \\ :no_cache, options \\ nil) do
    cond do
      options[:raw] == false ->
        default = cond do
                    default == :no_cache -> {:fast_global, :no_cache, {:error, :cache_miss}}
                    :else -> default
                  end
        v = Noizu.FastGlobal.V3.Cluster.get(
          cache_key,
          default,
          options
        )
        case v do
          {:error, :cache_miss} -> {:error, :cache_miss}
          {:error, details} -> {:error, details}
          v -> {:ok, v}
        end
      :else ->
        case FastGlobal.get(cache_key, {:fast_global, :cache_miss}) do
          {:fast_global, :cache_miss} ->
            v = cond do
                  is_function(default, 0) -> default.()
                  default == :no_cache -> {:fast_global, :no_cache, {:error, :cache_miss}}
                  :else -> default
                end
            case v do
              {:fast_global, :no_cache, {:error, :cache_miss}} -> {:error, :cache_miss}
              {:fast_global, :no_cache, v} -> {:ok, v}
              v ->
                __write__(cache_key, v, options)
                {:ok, v}
            end
        end
    end
  end
  
  
  
  def cache_key(m, ref, _context, _options) do
    sref = m.__entity__.sref(ref)
    sref && :"e_c:#{sref}"
  end
  
  #------------------------------------------
  # delete_cache
  #------------------------------------------
  def delete_cache(m, ref, context, options) do
    cond do
      cache_key = m.cache_key(ref, context, options) ->
        Noizu.FastGlobal.V3.Cluster.delete(
          cache_key,
          options
        )
      :else -> throw "Invalid Ref #{m}.delete_cache(#{inspect ref})"
    end
  end

  def pre_cache(_m, nil, _context, _options), do: nil
  def pre_cache(m, ref, context, options) do
    cond do
      cache_key = m.cache_key(ref, context, options) ->
        Noizu.FastGlobal.V3.Cluster.put(
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
  def get_cache(_m, nil, _context, _options), do: nil
  def get_cache(m, ref, context, options) do
    cond do
      cache_key = m.cache_key(ref, context, options) ->
        v = Noizu.FastGlobal.V3.Cluster.get(
          cache_key,
          fn () ->
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