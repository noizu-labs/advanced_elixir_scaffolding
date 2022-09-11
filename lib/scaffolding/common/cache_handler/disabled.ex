defmodule Noizu.DomainObject.CacheHandler.Disabled do
  @behaviour Noizu.DomainObject.CacheHandler
  
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