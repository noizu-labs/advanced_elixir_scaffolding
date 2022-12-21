#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.DomainObject.CacheHandler do
  @moduledoc """
  CacheHandler Behaviour
  ========
  
  The CacheHandler Behavior defines how to check, update and clear cached DomainObject values to a specific cache mechanisms.
  The DomainObject.Repo uses a module providing this behavior to implement it's `cache/3`, `delete_cache/3` and `pre_cache/3` methods.
  
  FastGlobal will be used by default if the cache is not explicitly disabled or set in the DomainObject body using the `@cache` attribute.
  You may extend with your own implementation as needed. Simply put your provider's module name in the Handler portion of the `@cache` attribute.
  
  # Format
  ```elixir
  @cache :disabled
  @cache Handler # use default options
  @cache {Handler, Options}
  ```
  
  # Provided CacheHandlers handlers
  - `:fast_global` Noizu.FastGlobal.V3.Cluster (default)
  - `:con_cache` ets backed ConCache handler
  - `:disabled` no handler
  - `:redis` uses erlang term serialization
  - `:redis_json` uses json serialization
  - `:rocksdb` facebook rocksdb kv database backed cache handler.
  
  # Default Cache Options
  - `prime` automatically populate cache on Repo.cache miss.
  - `ttl` default ttl for cache entries
  - `miss_ttl` default ttl for error/cache-miss cache entries.
  
  
  # Example
  ```elixir
  defmodule MyDO do
    #...
    @cache {:redis, [prime: true, ttl: 123, miss_ttl: 5]}
    defmodule Entity do
      #...
    end
  
    defmodule Repo do
      #...
    end
  end
  
  # Interact
  MyDO.Repo.cache(1234, context, options)
  MyDO.Repo.delete_cache(1234, context, options)
  MyDO.Repo.pre_cache(object, context, options)
  ```
  """
  
  @callback delete_cache(m :: any, ref :: any, context :: any, options :: any) :: any
  @callback pre_cache(m :: any, ref :: any, context :: any, options :: any) :: any
  @callback get_cache(m :: any, ref :: any, context :: any, options :: any) :: any
  @callback cache_key(m :: any, ref :: any, context :: any, options :: any) :: any
end
