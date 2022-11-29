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
  
  @callback __write__(cache_key :: any, value :: any, options :: any) :: :ok | {:error, any}
  @callback __fetch__(cache_key :: any, default :: any, options :: any) :: {:ok, any} | {:error, :cache_miss} | {:error, any}
  @callback __clear__(cache_key :: any, options :: any) :: :ok | {:error, any}
end
