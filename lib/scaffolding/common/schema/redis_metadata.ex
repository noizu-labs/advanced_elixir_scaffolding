defmodule Noizu.AdvancedScaffolding.Schema.RedisMetadata do
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
