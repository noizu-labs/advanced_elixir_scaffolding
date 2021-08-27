defmodule Noizu.AdvancedScaffolding.Schema.Metadata do
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
