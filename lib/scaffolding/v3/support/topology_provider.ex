#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.Support.TopologyProvider do
  @behaviour Noizu.MnesiaVersioning.TopologyBehaviour

  def mnesia_nodes() do
    {:ok, [node()]}
  end

  def database() do
    [Noizu.Scaffolding.V3.Database]
  end
end
