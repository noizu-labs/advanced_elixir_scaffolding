#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Test.Fixture.NmidGenerator do
  def generate(_seq, _opts) do
    :os.system_time(:micro_seconds)
  end
  def generate!(seq, opts) do
    generate(seq, opts)
  end
end

