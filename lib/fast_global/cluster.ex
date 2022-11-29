#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.FastGlobal.V3.Cluster do
  @vsn 1.0
  alias Noizu.FastGlobal.V3.Record

  def get_settings() do
    get(:fast_global_settings,
      fn() ->
        try do
          if :ok == Noizu.FastGlobal.V3.Database.Settings.wait(100) do
            case Noizu.FastGlobal.V3.Database.Settings.read!(:fast_global_settings) do
              %Noizu.FastGlobal.V3.Database.Settings{value: v} -> v
              _ -> {:fast_global, :no_cache, %{}}
            end
          else
            {:fast_global, :no_cache, %{}}
          end
        rescue _e -> {:fast_global, :no_cache, %{}}
        catch _e -> {:fast_global, :no_cache, %{}}
        end
      end
    )
  end

  #-------------------
  # sync_record
  #-------------------
  def sync_record(identifier, default, options) do
    r = (if Semaphore.acquire({:fg_write_record, identifier}, 1) do
           try do
             settings = cond do
                          identifier == :fast_global_settings -> %{}
                          :else -> get_settings()
                        end
             origin = options[:origin] || settings[:origin]
             record = try do
                        origin && :rpc.call(origin, __MODULE__, :get_record, [identifier], 15_000)
             rescue _e -> nil
             catch _e -> nil
                      end
      
             case record do
               %Record{value: value} ->
                 r = cond do
                       options[:fg_sync] -> put(identifier, record)
                       :else -> spawn fn -> put(identifier, record) end
                     end
                 case r do
                   :ok -> value
                   true -> value
                   error -> {:fast_global, :no_cache, error}
                 end
               _ ->
                 value = (if is_function(default, 0) do
                            default.()
                          else
                            default
                          end)
                 case value do
                   {:fast_global, :no_cache, _} -> value
                   _ ->
                     record = %Record{identifier: identifier, origin: origin || node(), pool: [node()], value: value, revision: 1, ts: :os.system_time(:millisecond)}
                     r = cond do
                           options[:fg_sync] -> put(identifier, record)
                           :else -> spawn fn -> put(identifier, record) end
                         end
                     case r do
                       :ok -> value
                       true -> value
                       error -> {:fast_global, :no_cache, error}
                     end
                 end
             end
           rescue _e -> nil
           catch _e -> nil
           end
           Semaphore.release({:fg_write_record, identifier})
         else
           if is_function(default, 0) do
             default.()
           else
             default
           end
         end)

    case r do
      {:fast_global, :no_cache, v} -> v
      v -> v
    end
  end

  @doc """
    @todo in the future instead of deleting fast global we should simply place a special sentinel value so that
  we retain our node list and origin.
  """
  def delete(key, options) do
    s = node()
    nodes = (options[:nodes] || Node.list()) ++ [s]
    timeout = options[:fg_timeout] || :infinity
    max_concurrency = options[:fg_concurrency] || length(nodes)
    r = cond do
      options[:fg_sync] ->
        Task.async_stream(nodes, fn (n) ->
                                    v = cond do
                                      n == s -> FastGlobal.delete(key)
                                      :else -> :rpc.call(n, FastGlobal, :delete, [key])
                                    end
                                    {n, v}
        end, max_concurrency: max_concurrency, timeout: timeout)
      :else ->
        Task.async_stream(nodes, fn (n) ->
          v = cond do
            n == s -> spawn fn -> FastGlobal.delete(key) end
            :else -> :rpc.cast(n, FastGlobal, :delete, [key])
          end
          {n, v}
        end, max_concurrency: max_concurrency, timeout: timeout)
    end |> Enum.filter(fn(o) ->
      case o do
        {:ok, {_, :ok}} -> false
        {:ok, {_, true}} -> false
        _ -> true
      end
    end) |> Enum.map(fn(o) ->
      case o do
        {:ok, v} -> v
        v -> v
      end
    end)
    
    case r do
      [] -> :ok
      error_list -> {:error, error_list}
    end
  end
  
  #-------------------
  # get
  #-------------------
  def get(identifier), do: get(identifier, nil, %{})
  def get(identifier, default), do: get(identifier, default, %{})
  def get(identifier, default, options) do
    case FastGlobal.get(identifier, {:fast_global, :cache_miss}) do
      %Record{value: v} -> v
      {:fast_global, :cache_miss} -> sync_record(identifier, default, options)
      error -> error
    end
  end

  #-------------------
  # get_record/1
  #-------------------
  def get_record(identifier), do: FastGlobal.get(identifier)

  #-------------------
  # put/3
  #-------------------
  def put(identifier, value, options \\ %{})
  def put(identifier, %Record{} = record, _options) do
    FastGlobal.put(identifier, record)
  end
  def put(identifier, value, options) do
    settings = get_settings()
    origin = options[:origin] || settings[:origin]
    cond do
      origin == node() -> coordinate_put(identifier, value, settings, options)
      origin == nil -> :error
      options[:fg_sync] ->
        timeout = options[:fg_timeout] || 30_000
        :rpc.call(origin, Noizu.FastGlobal.V3.Cluster, :coordinate_put, [identifier, value, settings, options], timeout: timeout)
      :else ->
        case :rpc.cast(origin, Noizu.FastGlobal.V3.Cluster, :coordinate_put, [identifier, value, settings, options]) do
          true -> :ok
          error -> error
        end
    end
  end

  #-------------------
  # coordinate_put
  #-------------------
  def coordinate_put(identifier, value, settings, options) do
    update = case get_record(identifier) do
      %Record{} = record ->
        pool = options[:pool] || settings[:pool] || []
        pool = ([node()] ++ pool) |> Enum.uniq()
        %Record{record| origin: node(), pool: pool, value: value, revision: record.revision + 1, ts: :os.system_time(:millisecond)}
      nil ->
        pool = options[:pool] || settings[:pool] || []
        pool = ([node()] ++ pool) |> Enum.uniq()
        %Record{identifier: identifier, origin: node(), pool: pool, value: value, revision: 1, ts: :os.system_time(:millisecond)}
    end
    
    if Semaphore.acquire({:fg_update_record, identifier}, 1) do
      s = node()
      timeout = options[:fg_timeout] || 30_000
      max_concurrency = options[:fg_concurrency] || length(update.pool)
      response = (try do
                    r = Task.async_stream(update.pool,
                      fn(n) ->
                        r = try do
                          cond do
                            options[:fg_sync] ->
                              cond do
                                n == s -> put(identifier, update, options)
                                :else -> :rpc.call(n, Noizu.FastGlobal.V3.Cluster, :put, [identifier, update, options], timeout: timeout)
                              end
                            :else ->
                              cond do
                                n == s -> spawn fn -> put(identifier, update, options) end
                                :else -> :rpc.cast(n, Noizu.FastGlobal.V3.Cluster, :put, [identifier, update, options])
                              end
                          end
                        rescue e ->
                          {:error, {:rescue, e}}
                        catch
                          :exit, e ->
                            {:error, {:exit, e}}
                          e -> {:error, {:exit, e}}
                        end
                        {n, r}
                      end,
                      max_concurrency: max_concurrency,
                      timeout: timeout
                    ) |> Enum.filter(fn(outcome) ->
                      case outcome do
                        {:ok, {_, :ok}} -> false
                        {:ok, {_, true}} -> false
                      end
                    end) |> Enum.map(fn(outcome) ->
                      case outcome do
                        {:ok, v} -> v
                        e -> e
                      end
                    end)
                    case r do
                      [] -> :ok
                      v -> {:error, v}
                    end
                  rescue e ->
                    {:error, {:rescue, e}}
                  catch
                    :exit, e ->
                      {:error, {:exit, e}}
                    e -> {:error, {:exit, e}}
                  end)
      Semaphore.release({:fg_update_record, identifier})
      response
    else
      {:error, {:fastglobal, :obtain_lock}}
    end
  end
end
