defmodule Noizu.Scaffolding.V3.Schema.PersistenceSettings do
  @vsn 1.0
  @type t :: %__MODULE__{
               layers: [Noizu.Scaffolding.V3.Schema.PersistenceLayer.t],
               ecto_entity: true | nil,
               mnesia_backend: nil | Map.t,
               ref_module: boolean,
               universal?: boolean,
               vsn: float
             }

  defstruct [
    layers: [],
    ecto_entity: nil,
    mnesia_backend: nil,
    ref_module: false,
    universal?: false,
    vsn: @vsn
  ]
end
