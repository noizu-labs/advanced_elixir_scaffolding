#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

# http://elixir-lang.org/docs/stable/ex_unit/ExUnit.html#start/1

Application.ensure_started(:semaphore)
Application.ensure_started(:fast_global)
ExUnit.configure formatters: [JUnitFormatter, ExUnit.CLIFormatter]

# Danger Will Robinson.
alias NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table, as: FooV3Table
alias NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Type.Table, as: FooV3TypeTable
alias Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, as: NmidV3Generator

#Amnesia.stop
#Amnesia.Schema.destroy
Amnesia.Schema.create()
Amnesia.start

children = [{Task.Supervisor, name: Noizu.FastGlobal.Cluster}]
{:ok, sup} = Supervisor.start_link(children, [strategy: :one_for_one, name: Test.Supervisor, strategy: :one_for_one])
Supervisor.start_child(sup, NoizuSchema.Redis.child_spec(nil))
Supervisor.start_child(sup, {ConCache, [name: ConCache.Default, ttl_check_interval: :timer.seconds(1), global_ttl: :timer.seconds(600)]})

if Code.ensure_loaded?(:rocksdb) do
  Supervisor.start_child(sup, {Noizu.RocksDB.Supervisor, {[:apple, :bottom, EntityCache], []}   })
  if !Amnesia.Table.exists?(NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.RocksDB.Table), do: NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.RocksDB.Table.create(memory: [node()])
end


if !Amnesia.Table.exists?(NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.ConCache.Table), do: NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.ConCache.Table.create(memory: [node()])
if !Amnesia.Table.exists?(NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.RedisJsonCache.Table), do: NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.RedisJsonCache.Table.create(memory: [node()])
if !Amnesia.Table.exists?(NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Table), do: NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Table.create(memory: [node()])
if !Amnesia.Table.exists?(FooV3Table), do: FooV3Table.create(memory: [node()])
if !Amnesia.Table.exists?(FooV3TypeTable), do: FooV3TypeTable.create(memory: [node()])
if !Amnesia.Table.exists?(NmidV3Generator), do: NmidV3Generator.create(memory: [node()])

ExUnit.start(capture_log: true)
