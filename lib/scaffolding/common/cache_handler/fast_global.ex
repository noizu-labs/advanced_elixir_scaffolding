defmodule Noizu.DomainObject.CacheHandler.FastGlobal do
  @behaviour Noizu.DomainObject.CacheHandler
  
  def cache_key(m, ref, context, options) do
    sref = m.__entity__.sref(ref)
    sref && :"e_c:#{sref}"
  end
  
  #------------------------------------------
  # delete_cache
  #------------------------------------------
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