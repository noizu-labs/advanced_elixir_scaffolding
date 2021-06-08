defmodule Noizu.Scaffolding.V3.Schema.EctoMetadata do
  @vsn 1.0
  @type t :: %__MODULE__{
               database: atom,
               repo: atom,
               vsn: float
             }

  defstruct [
    database: nil,
    repo: nil,
    vsn: @vsn
  ]
end
