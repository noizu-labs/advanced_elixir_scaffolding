#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Schema.Metadata.Other do
  @moduledoc """
  Generic Metadata for non Redis/ecto/mnesia persistence layers.
  """

  @vsn 1.0
  @type t :: %__MODULE__{
               database: atom,
               type: atom,
               repo: atom,
               vsn: float
             }

  defstruct [
    database: nil,
    type: nil,
    repo: nil,
    vsn: @vsn
  ]
end
