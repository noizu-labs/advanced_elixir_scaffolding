defmodule Noizu.DomainObject.CacheHandler.Disabled do
  @moduledoc """
  The `Noizu.DomainObject.CacheHandler.Disabled` module implements the `Noizu.DomainObject.CacheHandler` behaviour,
  providing cache handling functionality for disabled caching.

  This module is used when caching is disabled for DomainObjects. It simply returns default values and does not perform any caching operations.

  # Functions
  - `cache_key/4`: Generates a cache key for a given DomainObject, ref, context, and options.
  - `delete_cache/4`: Deletes a cache entry for a given DomainObject, ref, context, and options.
  - `pre_cache/4`: Pre-caches a DomainObject with a given ref, context, and options.
  - `get_cache/4`: Retrieves a cached DomainObject with a given ref, context, and options.

  # Code Review
  ✅ No code review notes.
  """

  @behaviour Noizu.DomainObject.CacheHandler
  #------------------------------------------
  # cache_key
  #------------------------------------------
  @doc """
  Generates a cache key based on the given DomainObject, ref, context, and options.

  ## Params
  - _m: The DomainObject module.
  - _ref: The reference to the DomainObject.
  - _context: The request context.
  - _options: A keyword list of options.

  ## Returns
  - nil: Caching is disabled, so no cache key is generated.
  """
  @spec cache_key(module(), any(), any(), Keyword.t()) :: nil
  def cache_key(m, ref, context, options)
  def cache_key(_m, _ref, _context, _options) do
    nil
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
  - true: The cache entry was deleted successfully.
  """
  @spec delete_cache(module(), any(), any(), Keyword.t()) :: true
  def delete_cache(m, ref, context, options)
  def delete_cache(_m, _ref, _context, _options) do
    true
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
  def pre_cache(_m, ref, _context, _options) do
    ref
  end

  #------------------------------------------
  # get_cache
  #------------------------------------------
  @doc """
  Retrieves a cached DomainObject with the given ref, context, and options.

  ## Params
  - _m: The DomainObject module.
  - nil: The reference to the DomainObject is nil.
  - _context: The request context.
  - _options: A keyword list of options.

  ## Returns
  - nil: Caching is disabled, so no cache entry is retrieved.
  """
  @spec get_cache(module(), nil, any(), Keyword.t()) :: nil
  def get_cache(m, nil, context, options)
  def get_cache(_m, nil, _context, _options), do: nil
  def get_cache(m, ref, context, options) do
    emit = m.emit_telemetry?(:cache, ref, context, options)
    emit && :telemetry.execute(m.telemetry_event(:cache, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
    emit && :telemetry.execute(m.telemetry_event(:cache_miss, ref, context, options), %{count: emit}, %{mod: m, handler:  __MODULE__})
    
    m.get!(ref, context, options)
  end
end
