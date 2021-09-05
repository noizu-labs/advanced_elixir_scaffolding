#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu LAbs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Support.Schema.Core do
  use Noizu.MnesiaVersioning.SchemaBehaviour
  use Amnesia
  use Noizu.AdvancedScaffolding.Database

  alias Noizu.MnesiaVersioning.ChangeSet

  @initial_tables [
    Noizu.AdvancedScaffolding.Database.UniversalReverseLookup.Table,
    Noizu.AdvancedScaffolding.Database.UniversalLookup.Table,
    Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table,
    Noizu.AdvancedScaffolding.Database.NmidV3Generator.Table,
  ]

  #-----------------------------------------------------------------------------
  # ChangeSets
  #-----------------------------------------------------------------------------
  def change_sets do
    [
      %ChangeSet{
        changeset:  "Initial Table Setup",
        author: "Keith Brings",
        note: "Initial Tables",
        update:
          fn() ->
            Enum.map(@initial_tables, fn(t) -> create_table(t, disk: [node()]) end)
            :success
          end,
        rollback:
          fn() ->
            Enum.map(Enum.reverse(@initial_tables), fn(t) -> destroy_table(t) end)
            :removed
          end
      },

    ]
  end

end
