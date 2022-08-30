#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.DomainObject.CacheHandler do
  @moduledoc """
  Responsible for writing entity to and from cache layer.
  """
  
  @callback delete_cache(m :: any, ref :: any, context :: any, options :: any) :: any
  @callback pre_cache(m :: any, ref :: any, context :: any, options :: any) :: any
  @callback get_cache(m :: any, ref :: any, context :: any, options :: any) :: any
  @callback cache_key(m :: any, ref :: any, context :: any, options :: any) :: any
end
