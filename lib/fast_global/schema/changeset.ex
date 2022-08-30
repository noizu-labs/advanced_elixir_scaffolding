#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.FastGlobal.V3.ChangeSet do
  alias Noizu.MnesiaVersioning.ChangeSet
  use Amnesia
  use Noizu.FastGlobal.V3.Database
  use Noizu.MnesiaVersioning.SchemaBehaviour

  def neighbors() do
    topology_provider = Application.get_env(:noizu_mnesia_versioning, :topology_provider)
    {:ok, nodes} = topology_provider.mnesia_nodes();
    nodes
  end
  #-----------------------------------------------------------------------------
  # ChangeSets
  #-----------------------------------------------------------------------------
  def change_sets do
    [
      %ChangeSet{
        changeset:  "FastGlobal Related Schema",
        author: "Keith Brings",
        note: "Y",
        environments: :all,
        update: fn() ->
                  neighbors = neighbors()
                  create_table(Noizu.FastGlobal.V3.Database.Settings, [disk: neighbors])
                  :success
        end,
        rollback: fn() ->
          destroy_table(Noizu.FastGlobal.V3.Database.Settings)
          :removed
        end
      }
    ]
  end
end
