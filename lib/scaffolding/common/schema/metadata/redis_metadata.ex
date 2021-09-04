#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Schema.Metadata.Redis do
  @moduledoc """
  Metadata field that must be added in a Redis handler module if used with the scaffolding framework.
  @example ```
  defmodule MyAppSchema.Redis do
    def child_spec(_args) do
    #...
    end

    def metadata(), do: %Noizu.Scaffolding.V3.Schema.RedisMetadata{repo: __MODULE__}
  end
  ```
  """

  @vsn 1.0
  @type t :: %__MODULE__{
               repo: atom,
               vsn: float
             }

  defstruct [
    repo: nil,
    vsn: @vsn
  ]
end
