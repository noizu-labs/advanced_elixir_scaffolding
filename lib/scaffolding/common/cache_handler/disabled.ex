defmodule Noizu.DomainObject.CacheHandler.Disabled do
  @behaviour Noizu.DomainObject.CacheHandler



  def __write__(cache_key, value, options \\ nil) do
    :ok
  end

  def __clear__(cache_key, options \\ nil) do
    :ok
  end

  def __fetch__(cache_key, default \\ :no_cache, options \\ nil) do
    {:error, :cache_miss}
  end
  
  
  def cache_key(_m, _ref, _context, _options) do
    nil
  end
  
  #------------------------------------------
  # delete_cache
  #------------------------------------------
  def delete_cache(_m, _ref, _context, _options) do
    true
  end

  #------------------------------------------
  # pre_cache
  #------------------------------------------
  def pre_cache(_m, ref, _context, _options) do
    ref
  end
  
  #------------------------------------------
  # get_cache
  #------------------------------------------
  def get_cache(_m, nil, _context, _options), do: nil
  def get_cache(m, ref, context, options) do
    m.get!(ref, context, options)
  end
end