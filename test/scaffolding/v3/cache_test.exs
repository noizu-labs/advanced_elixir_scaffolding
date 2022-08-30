#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.CacheTest do
  use ExUnit.Case
  use Amnesia
  use NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table
  #alias Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Entity
  #alias Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Repo
  #alias NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table
  #alias Noizu.ElixirCore.CallingContext
  require Logger
  Code.ensure_loaded?(Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema)
  
  setup do
    #Table.clear
    :ok
  end
  
  @tag :v3
  @tag :cache
  test "Redis Cache" do
    contents = "apple.#{:os.system_time(:second)}"
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Entity{identifier: :bar, content: contents, meta: %{apple: true}}
    cache = sut.__struct__.__noizu_info__(:cache)
    assert cache[:type] == Noizu.DomainObject.CacheHandler.Redis
    Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Repo.pre_cache(sut, Noizu.ElixirCore.CallingContext.system(), [])
    r = Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Repo.cache(Noizu.ERP.ref(sut), Noizu.ElixirCore.CallingContext.system(), [])
    assert r.content == contents
    assert %Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Entity{content: contents, identifier: :bar, meta: %{apple: true}} == r
    
    Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Repo.delete_cache(sut, Noizu.ElixirCore.CallingContext.system(), [])
    r = Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Repo.cache(Noizu.ERP.ref(sut), Noizu.ElixirCore.CallingContext.system(), [])
    assert r == nil

    r = Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Repo.cache(Noizu.ERP.ref(sut), Noizu.ElixirCore.CallingContext.system(), [])
    assert r == nil
  end


  @tag :v3
  @tag :cache
  test "Redis Cache Settings" do
    sut = Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Entity.__noizu_info__(:cache)
    assert sut[:type] == Noizu.DomainObject.CacheHandler.Redis
    assert sut[:schema] == :default
    assert sut[:ttl] == 123
    assert sut[:miss_ttl] == 5
    assert sut[:prime] == true
  end


  @tag :v3
  @tag :cache
  test "FastGlobal Cache" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.FastGlobalCache.Entity{identifier: :foo}
    cache = sut.__struct__.__noizu_info__(:cache)
    assert cache[:type] == Noizu.DomainObject.CacheHandler.FastGlobal
    Noizu.AdvancedScaffolding.Test.Fixture.V3.FastGlobalCache.Repo.pre_cache(sut, Noizu.ElixirCore.CallingContext.system(), [origin: node()])
    r = Noizu.AdvancedScaffolding.Test.Fixture.V3.FastGlobalCache.Repo.cache(Noizu.ERP.ref(sut), Noizu.ElixirCore.CallingContext.system(), [])
    assert r.identifier == :foo

    Noizu.AdvancedScaffolding.Test.Fixture.V3.FastGlobalCache.Repo.delete_cache(sut, Noizu.ElixirCore.CallingContext.system(), [])
    r = Noizu.AdvancedScaffolding.Test.Fixture.V3.FastGlobalCache.Repo.cache(Noizu.ERP.ref(sut), Noizu.ElixirCore.CallingContext.system(), [])
    assert r == nil
  end

  @tag :v3
  @tag :cache
  test "Disabled Cache" do
    sut = %Noizu.AdvancedScaffolding.Test.Fixture.V3.NoCache.Entity{identifier: :foo}
    cache = sut.__struct__.__noizu_info__(:cache)
    assert cache[:type] == Noizu.DomainObject.CacheHandler.Disabled
    Noizu.AdvancedScaffolding.Test.Fixture.V3.NoCache.Repo.pre_cache(sut, Noizu.ElixirCore.CallingContext.system(), [])
    r = Noizu.AdvancedScaffolding.Test.Fixture.V3.NoCache.Repo.cache(Noizu.ERP.ref(sut), Noizu.ElixirCore.CallingContext.system(), [])
    assert r == nil
  end


end
