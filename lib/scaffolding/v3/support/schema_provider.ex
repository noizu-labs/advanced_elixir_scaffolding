#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.Support.SchemaProvider do
  use Amnesia
  @behaviour Noizu.MnesiaVersioning.SchemaBehaviour

  def neighbors() do
    [node()]
  end

  #-----------------------------------------------------------------------------
  # ChangeSets
  #-----------------------------------------------------------------------------
  def change_sets do
    Noizu.Scaffolding.V3.Support.Schema.Core.change_sets()
  end

end # End Mix.Task.Migrate
