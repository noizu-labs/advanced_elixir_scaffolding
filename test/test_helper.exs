#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

# http://elixir-lang.org/docs/stable/ex_unit/ExUnit.html#start/1



# Danger Will Robinson.
alias NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Table, as: FooV3Table
alias NoizuSchema.Database.AdvancedScaffolding.Test.Fixture.V3.Foo.Type.Table, as: FooV3TypeTable
alias Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table, as: NmidV3Generator

#Amnesia.stop
#Amnesia.Schema.destroy
Amnesia.Schema.create()
Amnesia.start

if !Amnesia.Table.exists?(FooV3Table), do: FooV3Table.create(memory: [node()])
if !Amnesia.Table.exists?(FooV3TypeTable), do: FooV3TypeTable.create(memory: [node()])
if !Amnesia.Table.exists?(NmidV3Generator), do: NmidV3Generator.create(memory: [node()])

ExUnit.start(capture_log: true)
